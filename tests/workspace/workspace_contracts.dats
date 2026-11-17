#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "config/conf.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/syntax/ast.sats"
staload "data_ast/syntax/ast_dump.sats"
staload "data_ast/syntax/ast_verify.sats"
staload "data_ast/parser/block/blk_parse.sats"
staload "data_image/image.sats"
staload "data_image/img_png.sats"
staload "data_image/img_bmp.sats"
staload "data_image/img_jpg.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/tabs/ui_tab.sats"
staload "ui_workspace/tabs/ui_tab_history.sats"
staload "ui_workspace/commands/ui_cmd.sats"
staload "ui_workspace/commands/ui_keymap.sats"

macdef TEST_BUFFER_BYTES = 1024
macdef SESSION_FONT_PIXELS = 18
macdef SESSION_DOC_FONT_PIXELS = 72
macdef SESSION_SIDEBAR_PIXELS = 260
macdef DOCUMENT_CASES = 8

datatype Codec = Png | Bmp | Jpeg

fun check(ok: bool): int = if ok then 0 else 1
fun fixture(codec: Codec): Buf = case+ codec of
  | Png() => make_png() | Bmp() => make_bmp() | Jpeg() => make_jpg()
fun decode(codec: Codec,source: !Buf,width: &int >> _,height: &int >> _): Buf = case+ codec of
  | Png() => decode_png(source,width,height)
  | Bmp() => decode_bmp(source,width,height)
  | Jpeg() => decode_jpg(source,width,height)

fun fixture_pixels(codec: Codec,width: int,height: int,red: int,green: int,blue: int,tolerance: int): int = let
  val source=fixture(codec)
  var actual_width: int=0
  var actual_height: int=0
  val pixels=decode(codec,source,actual_width,actual_height)
  val dimensions=ieq(actual_width,width) andalso ieq(actual_height,height)
  val color=ile(iabs(isub(buf_get(pixels,0),red)),tolerance)
    andalso ile(iabs(isub(buf_get(pixels,1),green)),tolerance)
    andalso ile(iabs(isub(buf_get(pixels,2),blue)),tolerance)
    andalso ieq(buf_get(pixels,3),255)
  val ()=buf_free(source)
  val ()=buf_free(pixels)
in check(dimensions andalso color) end

fun reject_empty(codec: Codec): int = let
  val source=buf_make(1)
  var width: int=0
  var height: int=0
  val pixels=decode(codec,source,width,height)
  val rejected=ieq(width,0) andalso ieq(height,0)
  val ()=buf_free(pixels)
  val ()=buf_free(source)
in check(rejected) end

fun test_resize(root: string): int = let
  var path: Buf=buf_make(TEST_BUFFER_BYTES)
  val ()=buffer_append_string(path,root)
  val ()=buffer_append_string(path,"/fixture.png")
  val source=make_png()
  val written=fs_write_buf(buffer_c_string(path),source,buf_len(source))
  val ()=buf_free(source)
  val image=img_open()
  val loaded=img_load(image,buffer_c_string(path))
  val resized=img_resize(image,2,3)
  val valid=ieq(image_width(image),2) andalso ieq(image_height(image),3)
  val rejected=ieq(img_resize(image,0,3),0) andalso ieq(img_resize(image,2,~1),0)
  val retained=ieq(image_width(image),2) andalso ieq(image_height(image),3)
  val ()=img_free(image)
  val ()=buf_free(path)
in check(ieq(written,1) andalso ieq(loaded,1) andalso ieq(resized,1) andalso valid andalso rejected andalso retained) end

fun images(root: string): int = let
  val png=fixture_pixels(Png(),1,1,10,20,30,0)
  val bmp=fixture_pixels(Bmp(),2,1,10,20,30,0)
  val jpeg=fixture_pixels(Jpeg(),8,8,40,90,140,30)
  val malformed=iadd(reject_empty(Png()),iadd(reject_empty(Bmp()),reject_empty(Jpeg())))
in iadd(iadd(png,bmp),iadd(jpeg,iadd(malformed,test_resize(root)))) end

fun save_session(vault: string): void = let
  val ()=conf_set_active_vault(vault)
  var panes: Buf=buf_make(1)
  var directories: Buf=buf_make(TEST_BUFFER_BYTES)
  val tabs: Tabs=TNil()
  val ()=buffer_append_string(directories,"folder\n")
  val ()=conf_save_session_ex(vault,"fixture.ttf",SESSION_FONT_PIXELS,SESSION_DOC_FONT_PIXELS,0,1,0,1,1,
    SESSION_SIDEBAR_PIXELS,panes,directories,tabs)
  val ()=tabs_free(tabs)
  val ()=buf_free(panes)
in buf_free(directories) end

fun load_session(vault: string): int = let
  var font: Buf=buf_make(TEST_BUFFER_BYTES)
  var panes: Buf=buf_make(TEST_BUFFER_BYTES)
  var directories: Buf=buf_make(TEST_BUFFER_BYTES)
  var pixels: int=0 and doc_pixels: int=0 and view: int=0 and split: int=0 and active: int=0
  var right: int=0 and sidebar: int=0 and width: int=0
  val tabs=conf_load_session_ex(vault,font,pixels,doc_pixels,view,split,active,right,sidebar,width,panes,directories,TNil())
  val scalar_fields=ieq(pixels,SESSION_FONT_PIXELS) andalso ieq(doc_pixels,SESSION_DOC_FONT_PIXELS) andalso ieq(view,0) andalso ieq(split,1)
    andalso ieq(active,0) andalso ieq(right,1) andalso ieq(sidebar,1) andalso ieq(width,SESSION_SIDEBAR_PIXELS)
  val text_fields=ieq(c_strcmp(buffer_c_string(font),"fixture.ttf"),0)
    andalso ieq(c_strcmp(buffer_c_string(directories),"folder\n"),0)
  val ()=tabs_free(tabs)
  val ()=buf_free(font)
  val ()=buf_free(panes)
  val ()=buf_free(directories)
in check(scalar_fields andalso text_fields) end

fun check_md_strip_one(input: string, expected: string): int = let
  var src=buf_make(64); var out=buf_make(64)
  val ()=buffer_append_string(src,input)
  val ()=base_name_no_md(src,out)
  val ok=ieq(c_strcmp(buffer_c_string(out),expected),0)
  val ()=buf_free(src); val ()=buf_free(out)
in check(ok) end

fun configuration(root: string): int = let
  val ()=save_session(root)
  var active: Buf=buf_make(TEST_BUFFER_BYTES)
  val loaded=conf_get_active_vault(active)
  val selected=loaded andalso ieq(c_strcmp(buffer_c_string(active),root),0)
  val ()=buf_free(active)
  val strip_err=iadd(check_md_strip_one("/a/din/mini vird.md","mini vird"),
    iadd(check_md_strip_one("/a/din/not.MD","not"),
    iadd(check_md_strip_one("/a/din/resim.png","resim.png"),
    check_md_strip_one("/a/din/.md",".md"))))
in iadd(check(selected),iadd(load_session(root),strip_err)) end

fun document_case(index: int): string =
  if ieq(index,0) then "" else if ieq(index,1) then "alpha\nbeta\n"
  else if ieq(index,2) then "# Baslik\nTurkce İı\n"
  else if ieq(index,3) then "- Ana\n  - Alt\n- Son\n"
  else if ieq(index,4) then "```text\n# kod\n```\n"
  else if ieq(index,5) then "[baglanti](hedef) ve **vurgu**\n"
  else if ieq(index,6) then "é 🙂\n" else "| a | b |\n|---|---|\n| 1 | 2 |\n"

fun insert_bytes{remaining:nat} .<remaining>. (remaining: int(remaining),document: !Doc,text: string,index: int): void =
  if remaining > 0 then let
    val byte=buf_make(1)
    val ()=buf_set(byte,0,c_str_byte(text,index))
    val ()=doc_insert(document,buf_ptr(byte),1)
    val ()=buf_free(byte)
  in insert_bytes(remaining-1,document,text,iadd(index,1)) end else ()

fun compare_document(text: string): int = let
  val incremental=doc_open()
  val reference=doc_open()
  val ()=insert_bytes(airlock_nat(c_strlen(text)),incremental,text,0)
  val ()=doc_insert(reference,c_str_ptr(text),c_strlen(text))
  val ()=ast_parse_all(reference)
  var actual: Buf=buf_make(TEST_BUFFER_BYTES)
  var expected: Buf=buf_make(TEST_BUFFER_BYTES)
  val ()=ast_dump(incremental,actual)
  val ()=ast_dump(reference,expected)
  val ok=buffer_equal_from(actual,expected,0) andalso ieq(ast_verify(incremental),0)
    andalso ieq(ast_verify(reference),0)
  val ()=if ok then () else println!("event=document_mismatch source=",text,
    " incremental=",buffer_c_string(actual)," reference=",buffer_c_string(expected))
  val ()=buf_free(actual)
  val ()=buf_free(expected)
  val ()=doc_free(incremental)
  val ()=doc_free(reference)
in check(ok) end

fun undo_crash_regression(): int = let
  val doc = doc_open()
  val text = "first line\nsecond line\nthird line\n"
  val () = doc_insert(doc, c_str_ptr(text), c_strlen(text))
  val () = doc_insert(doc, c_str_ptr("extra\n"), 6)
  val () = doc_undo(doc)
  val () = doc_undo(doc)
  val () = doc_undo(doc)
  val () = doc_redo(doc)
  val () = doc_redo(doc)
  val ok1 = ieq(ast_verify(doc), 0) andalso igt(doc_len(doc), 0)
  val () = doc_free(doc)
in check(ok1) end

fun documents{remaining:nat} .<remaining>. (remaining: int(remaining),index: int): int =
  if remaining > 0 then iadd(compare_document(document_case(index)),documents(remaining-1,iadd(index,1))) else undo_crash_regression()

fun check_chord_flow(km: !Buf): int = let
  var ca = Off: Toggle; var cm = 0: int; var ck = 0: int
  val kz = c_str_byte("z", 0); val kx = c_str_byte("x", 0)
  val ks = c_str_byte("s", 0); val kg = c_str_byte("g", 0)
  val c_def = keymap_resolve(km, ca, cm, ck, KEYMOD_CTRL, kz, On)
  val c_pre = keymap_resolve(km, ca, cm, ck, KEYMOD_CTRL, kx, On)
  val on1 = is_cmd(c_pre, CMD_NONE) andalso is_on(ca)
  val c_sav = keymap_resolve(km, ca, cm, ck, KEYMOD_CTRL, ks, On)
  val off1 = is_cmd(c_sav, CMD_SAVE) andalso is_off(ca)
  val _ = keymap_resolve(km, ca, cm, ck, KEYMOD_CTRL, kx, On)
  val c_can = keymap_resolve(km, ca, cm, ck, KEYMOD_CTRL, kg, On)
in
  check(is_cmd(c_def, CMD_UNDO) andalso on1 andalso off1 andalso is_cmd(c_can, CMD_NONE) andalso is_off(ca))
end

fun keymap_file_roundtrip(): int = let
  var kp = buf_make(TEST_BUFFER_BYTES)
  val () = conf_keybindings_path(kp)
  var json = buf_make(256)
  val () = buffer_append_string(json, "[{\"key\":\"C-x C-s\",\"command\":\"save\"},{\"key\":\"Ctrl+Z\",\"command\":\"unbind\"}]\n")
  val jlen = buf_len(json)
  val wr = fs_write_buf(buffer_c_string(kp), json, jlen)
  var km = buf_make(4096)
  val () = conf_load_keybindings(km)
  var ca = Off: Toggle; var cm = 0: int; var ck = 0: int
  val c_unb = keymap_resolve(km, ca, cm, ck, KEYMOD_CTRL, c_str_byte("z", 0), On)
  val _ = keymap_resolve(km, ca, cm, ck, KEYMOD_CTRL, c_str_byte("x", 0), On)
  val c_sav = keymap_resolve(km, ca, cm, ck, KEYMOD_CTRL, c_str_byte("s", 0), On)
  val () = buf_free(kp); val () = buf_free(json); val () = buf_free(km)
in check(ieq(wr, 1) andalso is_cmd(c_unb, CMD_NONE) andalso is_cmd(c_sav, CMD_SAVE)) end

fun check_fmt_entry(km: !Buf, fmt: &Buf >> _): void =
  if igt(keymap_count(km), 0) then keymap_format_entry(km, 0, fmt) else ()

fun bind_if_ok(ok: bool, km: &Buf >> _, m1: int, k1: int, m2: int, k2: int, cmd: Cmd): void =
  if ok then keymap_bind(km, m1, k1, m2, k2, cmd) else ()

fun check_wheel_zoom_keymap(km: !Buf): int = let
  var ca = Off: Toggle; var cm = 0: int; var ck = 0: int
  val c_up = keymap_resolve(km, ca, cm, ck, KEYMOD_CTRL, KEYCODE_WHEEL_UP, On)
  val c_dn = keymap_resolve(km, ca, cm, ck, KEYMOD_CTRL, KEYCODE_WHEEL_DOWN, On)
  var wseq = buf_make(32); val () = buffer_append_string(wseq, "Ctrl+WheelUp")
  var m1 = 0: int; var k1 = 0: int; var m2 = 0: int; var k2 = 0: int
  val wlen = buf_len(wseq)
  val okp = keymap_parse_sequence(wseq, 0, wlen, m1, k1, m2, k2)
  val () = buf_free(wseq)
in
  check(is_cmd(c_up, CMD_DOC_FONT_INCREASE) andalso is_cmd(c_dn, CMD_DOC_FONT_DECREASE)
    andalso okp andalso ieq(m1, KEYMOD_CTRL) andalso ieq(k1, KEYCODE_WHEEL_UP))
end

fun keymap_contracts(): int = let
  var km = buf_make(4096)
  val () = keymap_load_defaults(km)
  val ew = check_wheel_zoom_keymap(km)
  var seq = buf_make(32); val () = buffer_append_string(seq, "C-x C-s")
  var m1 = 0: int; var k1 = 0: int; var m2 = 0: int; var k2 = 0: int
  val slen = buf_len(seq)
  val parsed = keymap_parse_sequence(seq, 0, slen, m1, k1, m2, k2)
  val () = bind_if_ok(parsed, km, m1, k1, m2, k2, CMD_SAVE)
  var fmt = buf_make(64)
  val () = check_fmt_entry(km, fmt)
  val e1 = check_chord_flow(km)
  val () = buf_free(seq); val () = buf_free(fmt); val () = buf_free(km)
in iadd(ew, iadd(check(parsed), iadd(e1, keymap_file_roundtrip()))) end

fun make_path_buf(s: string): Buf = let
  var b = buf_make(64); val () = buffer_append_string(b, s)
in b end

fun history_back_check(hl0: TabHistList, err: &int >> _): TabHistList = let
  val p3 = make_path_buf("/v/dir/c.md"); var out = buf_make(64)
  var osc = 0: int; var oc = 0: int
  val @(hl1, ok) = tab_hist_back(hl0, 0, p3, 45, 11, out, osc, oc)
  val out_ok = ieq(c_strcmp(buffer_c_string(out), "/v/dir/b.md"), 0)
  val good = ok andalso out_ok andalso ieq(osc, 30) andalso ieq(oc, 9)
  val () = err := iadd(err, check(good))
  val () = buf_free(p3); val () = buf_free(out)
in hl1 end

fun empty_history_replace_check(p1: !Buf): int = let
  var emp = buf_make(8)
  val hl_e0 = tab_hist_add(THNil(), emp, 0, 0)
  val hl_e1 = tab_hist_push(hl_e0, 0, emp, 0, 0, p1, 0, 0)
  val ok = not(tab_hist_can_back(hl_e1, 0))
  val () = tab_hist_free(hl_e1)
  val () = buf_free(emp)
in
  check(ok)
end

fun chrome_and_readable_contracts(): int = let
  val min_ok = ieq(chrome_topbar_h(16), UI_TOPBAR_HEIGHT) andalso ieq(chrome_hdr_h(16), UI_PANE_HEADER_HEIGHT)
  val big_ok = igt(chrome_topbar_h(50), UI_TOPBAR_HEIGHT) andalso igt(chrome_hdr_h(50), UI_PANE_HEADER_HEIGHT)
  val r_sm = ieq(readable_col_w(1400, 20), 850) andalso ieq(readable_col_x(0, 1400, 20), 275)
  val r_lg = igt(readable_col_w(1400, 50), 850) andalso ilt(readable_col_x(0, 1400, 50), 100)
in
  check(min_ok andalso big_ok andalso r_sm andalso r_lg)
end

fun history_contracts(): int = let
  var err: int = 0
  val p1 = make_path_buf("/v/dir/a.md"); val p2 = make_path_buf("/v/dir/b.md")
  val p3 = make_path_buf("/v/dir/c.md"); val p4 = make_path_buf("/v/dir/d.md")
  val old_p = make_path_buf("/v/dir"); val new_p = make_path_buf("/v/moved")
  val err_e = empty_history_replace_check(p1)
  val err_c = chrome_and_readable_contracts()
  val hl0 = tab_hist_add(THNil(), p1, 10, 5)
  val hl1 = tab_hist_push(hl0, 0, p1, 20, 7, p2, 0, 0)
  val hl2 = tab_hist_push(hl1, 0, p2, 30, 9, p3, 0, 0)
  val hl3 = history_back_check(hl2, err)
  val mid_ok = tab_hist_can_back(hl3, 0) andalso tab_hist_can_forward(hl3, 0)
  val hl4 = tab_hist_push(hl3, 0, p2, 31, 8, p4, 0, 0)
  val trunc_ok = tab_hist_can_back(hl4, 0) andalso not(tab_hist_can_forward(hl4, 0))
  val hl5 = tab_hist_rename_prefix(hl4, old_p, new_p)
  val hl6 = tab_hist_drop(tab_hist_move(tab_hist_clone(hl5, 0), 0, 1), 0)
  val len_ok = ieq(tab_hist_len(hl6), 1)
  val () = tab_hist_free(hl6)
  val () = (buf_free(p1); buf_free(p2); buf_free(p3); buf_free(p4); buf_free(old_p); buf_free(new_p))
in iadd(err, iadd(iadd(err_e, err_c), check(mid_ok andalso trunc_ok andalso len_ok))) end

fun run(mode: string,root: string): int =
  if ieq(c_strcmp(mode,"image"),0) then images(root)
  else if ieq(c_strcmp(mode,"config"),0) then configuration(root)
  else if ieq(c_strcmp(mode,"document"),0) then documents(DOCUMENT_CASES,0)
  else if ieq(c_strcmp(mode,"keymap"),0) then keymap_contracts()
  else if ieq(c_strcmp(mode,"history"),0) then history_contracts()
  else 1

implement main0() =
  if ine(c_argc(),3) then exit(2) else let
    val before=mem_live()
    val errors=run(c_argv(1),c_argv(2))
    val ownership=check(ieq(before,mem_live()))
    val total=iadd(errors,ownership)
    val ()=println!("event=workspace_contracts mode=",c_argv(1)," errors=",total)
  in if igt(total,0) then exit(1) else () end
