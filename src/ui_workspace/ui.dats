#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "os/diag.sats"
staload "core_platform/platform.sats"
staload "core_platform/x11.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "data_font/font.sats"
staload "data_ast/doc.sats"
staload "data_image/image.sats"
staload "ui_workspace/ui.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/ui_tree.sats"
staload "ui_workspace/ui_search.sats"
staload "ui_workspace/ui_menu.sats"
staload "ui_workspace/ui_tab.sats"
staload "ui_workspace/ui_render.sats"
staload "ui_workspace/ui_widgets.sats"
staload "config/conf.sats"
staload "ui_workspace/ui_cmd.sats"

fun iand(a: int, n: int): int = anth_iand(a, n)

fun plat_read_buf(p: !Plat, ev: &event, dst: !Buf, cap: int): int =
  plat_read(p, ev, buf_ptr(dst), cap)

fun plat_reply_buf(p: !Plat, ev: &event, data: !Buf, n: int): void =
  plat_reply(p, ev, buf_ptr(data), n)

fun ev_text_buf(ev: &event, dst: !Buf, n: int): int =
  ev_text(ev, buf_ptr(dst), n)

vtypedef App_record = @{
  vault= Buf, tabs= Tabs, cache= Cache,
  active= int, righti= int, split= Toggle, focus= Toggle, side= Sidebar, fontpx= int,
  clip= Buf, menu= MenuKind, menux= int, menuy= int, drag= DragKind, dragi= int,
  prompt= PromptKind, promptb= Buf, query= Buf, qfocus= Toggle,
  tree= Buf, tmeta= Buf, tn= int, hits= Buf, hmeta= Buf, hn= int,
  sel= int, treedirty= Toggle, paste= Toggle, hitk= NodeKind, hiti= int, downx= int, downy= int,
  scratch= Buf, imgpath= Buf, viewmode= ViewMode, font_idx= int,
  fpaths= Buf, fnames= Buf, fmeta= Buf, fcnt= int, font_path= Buf,
  vault_select= Toggle, vpaths= Buf, vnames= Buf, vmeta= Buf, vcnt= int,
  hoverx= int, hovery= int
}
datavtype App_ = APP of App_record
(* skill.md 1. kural istisnasi: ATS2 soyut tip gerceklemesi (sats'taki absviewtype). Kanit disi cast veya ham C yoktur. *)
assume App = App_

fun save_session_impl(vault: !Buf, font_p: !Buf, font_px: int, viewmode: ViewMode, split: Toggle, active: int, ts: !Tabs): void =
  if igt(buf_len(vault), 0) then
    conf_save_session(cstr(vault), cstr(font_p), font_px, view_mode_code(viewmode), toggle_int(split), active, ts)
  else ()

fun make_empty_tabs(): Tabs = let
  var title = buf_make(16)
  val () = bstr(title, "Isimsiz")
  var path = buf_make(4)
  val doc = doc_open()
in
  tabs_add(TNil(), doc, path, title)
end

fun tabs_fallback(ts: Tabs): Tabs =
  case+ ts of
  | ~TNil() => make_empty_tabs()
  | ~TCons(d, p, t, s, rest) => TCons(d, p, t, s, rest)

fun load_vault_tabs(target: string, font_path: &Buf >> Buf, out_fpx: &int >> int, out_vm: &int >> int, out_sp: &int >> int, out_act: &int >> int): Tabs = let
  var fpx: int = 18
  var vmode: int = 0
  var sp: int = 0
  var act_idx: int = 0
  val loaded_tabs = conf_load_session(target, font_path, fpx, vmode, sp, act_idx, TNil())
  val new_tabs = tabs_fallback(loaded_tabs)
  val () = out_fpx := (if igt(fpx, 0) then fpx else 18)
  val () = out_vm := vmode
  val () = out_sp := sp
  val () = out_act := act_idx
in
  new_tabs
end

fun init_vault_tabs(vb: !Buf, f_vsel: Toggle, font_path: &Buf >> Buf, out_fpx: &int >> int, out_vm: &int >> int, out_sp: &int >> int, out_act: &int >> int): Tabs =
  if ieq(buf_len(vb), 0) orelse is_on(f_vsel) then let
    val () = out_fpx := 18
    val () = out_vm := 0
    val () = out_sp := 0
    val () = out_act := 0
  in
    make_empty_tabs()
  end else let
    val () = conf_set_active_vault(cstr(vb))
  in
    load_vault_tabs(cstr(vb), font_path, out_fpx, out_vm, out_sp, out_act)
  end

fun switch_vault_tabs(old_tabs: Tabs, target: string, font_path: &Buf >> Buf, out_fpx: &int >> int, out_vm: &int >> int, out_sp: &int >> int, out_act: &int >> int): Tabs = let
  val () = tabs_save_all_physical(old_tabs)
  val () = tabs_free(old_tabs)
in
  load_vault_tabs(target, font_path, out_fpx, out_vm, out_sp, out_act)
end

fun vault_switch_begin(s: &App_record >> _, target: string): void = let
  val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
  val () = bclear(s.vault)
  val () = bstr(s.vault, target)
  val () = conf_set_active_vault(target)
in
end

fun vault_switch_finish(s: &App_record >> _, new_t: Tabs, fpx: int, vm: int, sp: int, act: int): void = let
  val ph = s.tabs
  val () = s.tabs := new_t
  val () = tabs_free(ph)
  val () = s.fontpx := fpx
  val () = s.viewmode := view_mode_of_code(vm)
  val () = s.split := toggle_of(ieq(sp, 1))
  val () = s.active := act
  val () = s.righti := 0
  val () = s.treedirty := On
  val () = bclear(s.promptb)
  val () = s.vault_select := Off
in
end

fun switch_to_vault(s: &App_record >> _, target: string): void = let
  val () = vault_switch_begin(s, target)
  val old_t = s.tabs
  val () = s.tabs := TNil()
  var n_fpx: int = 18
  var n_vm: int = 0
  var n_sp: int = 0
  var n_act: int = 0
  val new_t = switch_vault_tabs(old_t, target, s.font_path, n_fpx, n_vm, n_sp, n_act)
  val () = vault_switch_finish(s, new_t, n_fpx, n_vm, n_sp, n_act)
in
end

fun set_vault_from_active(vb: &Buf >> Buf, out_vsel: &int >> int, s_act: string): void = let
  val () = bstr(vb, s_act)
  val () = out_vsel := 0
in
end

fun set_vault_from_picker(out_vsel: &int >> int): void = let
  val () = out_vsel := 1
in
end

fun resolve_vault_buffer(vb: &Buf >> Buf, out_vsel: &int >> int): void =
  if ieq(buf_len(vb), 0) then let
    var act = buf_make(256)
    val found = conf_get_active_vault(act)
    val s_act = cstr(act)
    val act_ex = if igt(buf_len(act), 0) then fs_exists(s_act) else 0
    val () = if found andalso ieq(act_ex, 1) then set_vault_from_active(vb, out_vsel, s_act)
      else set_vault_from_picker(out_vsel)
    val () = buf_free(act)
  in
    ()
  end else let
    val () = conf_set_active_vault(cstr(vb))
    val () = out_vsel := 0
  in
    ()
  end

fun pick_first_font(fpath: &Buf >> Buf, fpaths: !Buf, fmeta: !Buf, fcnt: int): void =
  if ieq(buf_len(fpath), 0) andalso igt(fcnt, 0) then let
    val poff = buf_get32(fmeta, 0)
    val plen = buf_get32(fmeta, 1)
    val () = bcat(fpath, fpaths, poff, iadd(poff, plen))
  in
    ()
  end else ()

fun open_resolve_vault(vault: string): @(Buf, int) = let
  var vb = buf_make(256)
  val () = bstr(vb, vault)
  var f_vsel: int = 0
  val () = resolve_vault_buffer(vb, f_vsel)
in
  @(vb, f_vsel)
end

fun open_scan_fonts(): @(Buf, Buf, Buf, int) = let
  var fpaths = buf_make(2048)
  var fnames = buf_make(1024)
  var fmeta = buf_make(512)
  var fcnt: int = 0
  val () = font_scan_fonts("fonts", fpaths, fnames, fmeta, fcnt)
in
  @(fpaths, fnames, fmeta, fcnt)
end

fun open_scan_vaults(): @(Buf, Buf, Buf, int) = let
  var vpaths = buf_make(2048)
  var vnames = buf_make(512)
  var vmeta = buf_make(512)
  var vcnt: int = 0
  val () = conf_list_vaults(vpaths, vnames, vmeta, vcnt)
in
  @(vpaths, vnames, vmeta, vcnt)
end

fun open_init_session(vb: !Buf, f_vsel: Toggle, fpaths: !Buf, fmeta: !Buf, fcnt: int): @(Tabs, Buf, int, int, int, int) = let
  var fpath = buf_make(256)
  var fpx: int = 18
  var vmode: int = 0
  var sp: int = 0
  var act_idx: int = 0
  val tabs = init_vault_tabs(vb, f_vsel, fpath, fpx, vmode, sp, act_idx)
  val () = pick_first_font(fpath, fpaths, fmeta, fcnt)
in
  @(tabs, fpath, fpx, vmode, sp, act_idx)
end

implement app_open(vault) = let
  val @(vb, f_vsel) = open_resolve_vault(vault)
  val @(fpaths, fnames, fmeta, fcnt) = open_scan_fonts()
  val @(vpaths, vnames, vmeta, vcnt) = open_scan_vaults()
  val @(tabs, fpath, fpx, vmode, sp, act_idx) = open_init_session(vb, toggle_of(ieq(f_vsel, 1)), fpaths, fmeta, fcnt)
in
  APP(@{
    vault= vb, tabs= tabs, cache= CNil(),
    active= act_idx, righti= 0, split= toggle_of(ieq(sp, 1)), focus= Off, side= SideNone, fontpx= fpx,
    clip= buf_make(64), menu= MenuNone, menux= 0, menuy= 0, drag= DragNone, dragi= ~1,
    prompt= PromptNone, promptb= buf_make(256), query= buf_make(64), qfocus= Off,
    tree= buf_make(64), tmeta= buf_make(64), tn= 0, hits= buf_make(64), hmeta= buf_make(64), hn= 0,
    sel= ~1, treedirty= On, paste= Off, hitk= KNone, hiti= ~1, downx= ~1, downy= ~1,
    scratch= buf_make(4096), imgpath= buf_make(64), viewmode= view_mode_of_code(vmode), font_idx= 0,
    fpaths= fpaths, fnames= fnames, fmeta= fmeta, fcnt= fcnt, font_path= fpath,
    vault_select= toggle_of(ieq(f_vsel, 1)), vpaths= vpaths, vnames= vnames, vmeta= vmeta, vcnt= vcnt,
    hoverx= ~1, hovery= ~1
  })
end

fun free_input_bufs(clip: Buf, promptb: Buf, query: Buf, tree: Buf, tmeta: Buf): void = let
  val () = buf_free(clip)
  val () = buf_free(promptb)
  val () = buf_free(query)
  val () = buf_free(tree)
  val () = buf_free(tmeta)
in
end

fun free_search_bufs(hits: Buf, hmeta: Buf, scratch: Buf, imgpath: Buf): void = let
  val () = buf_free(hits)
  val () = buf_free(hmeta)
  val () = buf_free(scratch)
  val () = buf_free(imgpath)
in
end

fun free_font_bufs(fpaths: Buf, fnames: Buf, fmeta: Buf, font_path: Buf): void = let
  val () = buf_free(fpaths)
  val () = buf_free(fnames)
  val () = buf_free(fmeta)
  val () = buf_free(font_path)
in
end

implement app_free(a) = let
  val+ ~APP(s) = a
  val ts2 = tabs_ensure_paths(s.tabs, s.vault)
  val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, ts2)
  val () = buf_free(s.vault)
  val () = tabs_free(ts2)
  val () = cache_free(s.cache)
  val () = free_input_bufs(s.clip, s.promptb, s.query, s.tree, s.tmeta)
  val () = free_search_bufs(s.hits, s.hmeta, s.scratch, s.imgpath)
  val () = free_font_bufs(s.fpaths, s.fnames, s.fmeta, s.font_path)
  val () = buf_free(s.vpaths)
  val () = buf_free(s.vnames)
in
  buf_free(s.vmeta)
end

fun pane_of(sfocus: Toggle, active: int, righti: int): int =
  if is_off(sfocus) then active else righti
fun ensure_tree_fresh(s: &App_record >> _): void =
  if is_on(s.treedirty) andalso is_side_files(s.side) then let
    val () = bclear(s.tree)
    val () = bclear(s.tmeta)
    val () = s.tn := 0
    val () = scan_dir(s.vault, 0, s.tmeta, s.tree, s.tn)
    val () = if ige(s.sel, s.tn) then s.sel := ~1 else ()
  in
    s.treedirty := Off
  end else ()

fun draw_search_plain_hit(f: !Font, r: !Rend, hits: !Buf, hmeta: !Buf, row: int): void = let
  val off = buf_get32(hmeta, iadd(imul(row, 4), 1))
  val n = buf_get32(hmeta, iadd(imul(row, 4), 2))
  val () = seen_int(hit_text(hits, off, n, f, r, 12, iadd(100, imul(row, 18)), col_accent()))
in
end

fun draw_search_marked_hit(f: !Font, r: !Rend, hits: !Buf, hmeta: !Buf, row: int): void = let
  val moff = buf_get32(hmeta, imul(row, 4))
  val off = buf_get32(hmeta, iadd(imul(row, 4), 1))
  val n = buf_get32(hmeta, iadd(imul(row, 4), 2))
  val ml = buf_get32(hmeta, iadd(imul(row, 4), 3))
  val y = iadd(100, imul(row, 18))
  val a1 = hit_text(hits, off, moff, f, r, 20, y, col_muted())
  val a2 = hit_text(hits, iadd(off, moff), ml, f, r, iadd(20, a1), y, col_hightxt())
  val () = seen_int(hit_text(hits, iadd(off, iadd(moff, ml)), isub(n, iadd(moff, ml)), f, r, iadd(20, iadd(a1, a2)), y, col_muted()))
in
end

fun draw_search_row(f: !Font, r: !Rend, hits: !Buf, hmeta: !Buf, row: int): void =
  if ilt(buf_get32(hmeta, imul(row, 4)), 0) then draw_search_plain_hit(f, r, hits, hmeta, row)
  else draw_search_marked_hit(f, r, hits, hmeta, row)

extern fun search_rows_exh(f: !Font, r: !Rend, s: &App_record, row: int, hn: int): void = "mac#anth_die_void"

fun search_rows_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, s: &App_record, row: int, hn: int): void =
  if recfuel > 0 then (
    if ilt(row, hn) andalso ilt(row, 24) then let
      val () = draw_search_row(f, r, s.hits, s.hmeta, row)
    in
      search_rows_m(recfuel - 1, f, r, s, iadd(row, 1), hn)
    end else ()
  ) else search_rows_exh(f, r, s, row, hn)

fun draw_sidebar_search(f: !Font, r: !Rend, s: &App_record): void = let
  val qn = buf_len(s.query)
  val () = ui_line_edit_draw(f, r, 8, 68, 264, 24, s.query, qn, qn, s.qfocus, "Aramak icin yazin...")
in
  search_rows_m(airlock_nat(MAX_REC_FUEL), f, r, s, 0, s.hn)
end

fun draw_tree_row(f: !Font, r: !Rend, s: &App_record, row: int): void = let
  val depth = buf_get32(s.tmeta, imul(row, 4))
  val mark = meta_dir(s.tmeta, row)
  val off = buf_get32(s.tmeta, iadd(imul(row, 4), 2))
  val n = buf_get32(s.tmeta, iadd(imul(row, 4), 3))
  var base = buf_make(8)
  val () = bcat(base, s.tree, off, iadd(off, n))
  val () = base_name(base, s.scratch)
  val icon = if is_dir_mark(mark, DirYes) then UI_ICON_FOLDER else UI_ICON_FILE
  val is_sel = ieq(s.sel, row)
  val row_y = iadd(72, imul(row, 18))
  val is_hov = ige(s.hoverx, 6) andalso ilt(s.hoverx, 274) andalso ige(s.hovery, row_y) andalso ilt(s.hovery, iadd(row_y, 18))
  val () = ui_cell(f, r, 6, row_y, 268, 18, depth, toggle_of(is_dir_mark(mark, DirYes)), toggle_of(is_dir_mark(mark, DirYes)), icon, cstr(s.scratch), "", toggle_of(is_sel), toggle_of(is_hov))
  val () = buf_free(base)
in
end

extern fun file_rows_exh(f: !Font, r: !Rend, s: &App_record, row: int, tn: int): void = "mac#anth_die_void"

fun file_rows_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, s: &App_record, row: int, tn: int): void =
  if recfuel > 0 then (
    if ilt(row, tn) andalso ilt(row, 28) then let
      val () = draw_tree_row(f, r, s, row)
    in
      file_rows_m(recfuel - 1, f, r, s, iadd(row, 1), tn)
    end else ()
  ) else file_rows_exh(f, r, s, row, tn)

fun draw_sidebar_files(f: !Font, r: !Rend, s: &App_record): void =
  file_rows_m(airlock_nat(MAX_REC_FUEL), f, r, s, 0, s.tn)

fun draw_config_vault_section(f: !Font, r: !Rend, s: &App_record): void = let
  val () = draw_s(f, r, 12, 76, "Kasa", col_muted())
  val vn = buf_len(s.vault)
  val () =
    if igt(vn, 0) then seen_int(font_draw_buf(f, r, 12, 94, s.vault, imin(vn, 28), col_text()))
    else seen_int(font_draw(f, r, 12, 94, c_str_ptr("(Secilmedi)"), 10, col_text()))
  val () = ui_button(f, r, 12, 122, 150, 22, "Kasayi Degistir", Off, Off)
in
end

fun draw_config_font_size(f: !Font, r: !Rend, s: &App_record): void = let
  val () = draw_s(f, r, 12, 154, "Yazi Boyutu (tikla)", col_text())
  val pxlab = if ieq(s.fontpx, 16) then "16 px" else if ieq(s.fontpx, 20) then "20 px" else "18 px"
  val () = ui_badge(f, r, 190, 152, pxlab, col_bar(), col_accent())
in
end

fun draw_config_font_row(f: !Font, r: !Rend, s: &App_record, fi: int): void = let
  var pbuf = buf_make(256)
  var nbuf = buf_make(64)
  val fy = iadd(210, imul(fi, 22))
  val poff = buf_get32(s.fmeta, imul(fi, 4))
  val plen = buf_get32(s.fmeta, iadd(imul(fi, 4), 1))
  val noff = buf_get32(s.fmeta, iadd(imul(fi, 4), 2))
  val nlen = buf_get32(s.fmeta, iadd(imul(fi, 4), 3))
  val () = bcat(pbuf, s.fpaths, poff, iadd(poff, plen))
  val () = bcat(nbuf, s.fnames, noff, iadd(noff, nlen))
  val is_sel = ieq(c_strcmp(cstr(pbuf), cstr(s.font_path)), 0)
  val f_icon = if is_sel then UI_ICON_CHECK else UI_ICON_CHECK_EMPTY
  val is_hov = ige(s.hoverx, 12) andalso ilt(s.hoverx, 268) andalso ige(s.hovery, fy) andalso ilt(s.hovery, iadd(fy, 22))
  val () = ui_cell(f, r, 12, fy, 256, 22, 0, Off, Off, f_icon, cstr(nbuf), "", toggle_of(is_sel), toggle_of(is_hov))
  val () = buf_free(pbuf)
  val () = buf_free(nbuf)
in
end

extern fun font_rows_exh(f: !Font, r: !Rend, s: &App_record, fi: int, fcnt: int): void = "mac#anth_die_void"

fun font_rows_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, s: &App_record, fi: int, fcnt: int): void =
  if recfuel > 0 then (
    if ilt(fi, fcnt) andalso ilt(fi, 12) then let
      val () = draw_config_font_row(f, r, s, fi)
    in
      font_rows_m(recfuel - 1, f, r, s, iadd(fi, 1), fcnt)
    end else ()
  ) else font_rows_exh(f, r, s, fi, fcnt)

fun draw_sidebar_config(f: !Font, r: !Rend, s: &App_record): void = let
  val () = draw_config_vault_section(f, r, s)
  val () = draw_config_font_size(f, r, s)
  val () = draw_s(f, r, 12, 186, "Yazi Tipi (fonts/)", col_text())
in
  font_rows_m(airlock_nat(MAX_REC_FUEL), f, r, s, 0, s.fcnt)
end

fun draw_side_frame(r: !Rend, h: int): void = let
  val () = rend_scissor(r, 0, 36, 280, isub(h, 36))
  val () = rend_rect(r, 0, 36, 280, isub(h, 36), col_side())
  val () = ui_divider(r, 0, 64, 280, Horizontal)
  val () = ui_divider(r, 279, 36, isub(h, 36), Vertical)
in
end

fun side_title(sd: Sidebar): string =
  if is_side_files(sd) then "Dosya Gezgini Aç/Kapa"
  else if is_side_search(sd) then "Genel Arama"
  else "Ayarlar"

fun draw_side_title(f: !Font, r: !Rend, sd: Sidebar): void = let
  val () = draw_s(f, r, 12, 44, side_title(sd), col_heading())
in
end

fun draw_side_body(f: !Font, r: !Rend, s: &App_record): void =
  if is_side_search(s.side) then draw_sidebar_search(f, r, s)
  else if is_side_files(s.side) then draw_sidebar_files(f, r, s)
  else draw_sidebar_config(f, r, s)

fun draw_side(f: !Font, r: !Rend, a: !App, h: int): void =
  case+ a of
  | @APP(s) => let
      val () = draw_side_frame(r, h)
      val () = draw_side_title(f, r, s.side)
      val () = ensure_tree_fresh(s)
      val () = draw_side_body(f, r, s)
      val () = rend_scissor_off(r)
    in
      fold@(a)
    end

fun ui_draw_menu(f: !Font, r: !Rend, a: !App): void =
  case+ a of
  | @APP(s) => let
      val () = draw_menu(f, r, s.menu, s.menux, s.menuy)
    in
      fold@(a)
    end

fun topbar_btn_x(idx: int): int =
  iadd(8, imul(idx, iadd(UI_TOPBAR_BTN_WIDTH, 6)))

fun topbar_tab_start_x(): int =
  iadd(iadd(topbar_btn_x(2), iadd(UI_TOPBAR_BTN_WIDTH, 14)), 16)

fun topbar_mode_btn_x(w: int): int =
  isub(w, iadd(UI_TOPBAR_BTN_WIDTH, 10))

fun topbar_btn_hovered(s: &App_record, x: int): bool =
  ige(s.hoverx, x) andalso ilt(s.hoverx, iadd(x, UI_TOPBAR_BTN_WIDTH)) andalso ige(s.hovery, 4) andalso ilt(s.hovery, 32)

fun draw_topbar_side_buttons(f: !Font, r: !Rend, s: &App_record): void = let
  val x1 = topbar_btn_x(0)
  val x2 = topbar_btn_x(1)
  val x3 = topbar_btn_x(2)
  val () = ui_icon_button(f, r, UI_ICON_FOLDER, "Gezgin", x1, 4, UI_TOPBAR_BTN_WIDTH, 28, toggle_of(is_side_files(s.side)), toggle_of(topbar_btn_hovered(s, x1)))
  val () = ui_icon_button(f, r, UI_ICON_SEARCH, "Arama", x2, 4, UI_TOPBAR_BTN_WIDTH, 28, toggle_of(is_side_search(s.side)), toggle_of(topbar_btn_hovered(s, x2)))
  val () = ui_icon_button(f, r, UI_ICON_SETTINGS, "Ayarlar", x3, 4, UI_TOPBAR_BTN_WIDTH, 28, toggle_of(is_side_config(s.side)), toggle_of(topbar_btn_hovered(s, x3)))
in
end

fun draw_topbar_chrome(f: !Font, r: !Rend, s: &App_record, w: int): void = let
  val tab_sep_x = iadd(topbar_btn_x(2), iadd(UI_TOPBAR_BTN_WIDTH, 14))
  val btxt = if is_view_edit(s.viewmode) then "Düzenle" else "Okuma"
  val bx = topbar_mode_btn_x(w)
  val () = rend_rect(r, 0, 0, w, UI_TOPBAR_HEIGHT, col_bar())
  val () = ui_divider(r, 0, 35, w, Horizontal)
  val () = draw_topbar_side_buttons(f, r, s)
  val () = ui_divider(r, tab_sep_x, 8, 20, Vertical)
  val hov_m = topbar_btn_hovered(s, bx)
in
  ui_button(f, r, bx, 4, UI_TOPBAR_BTN_WIDTH, 28, btxt, toggle_of(hov_m), toggle_of(is_view_edit(s.viewmode)))
end

fun draw_editor_panes(f: !Font, r: !Rend, s: &App_record >> _, ox: int, half: int, h: int, lh: int): void = let
  val tab_x0 = topbar_tab_start_x()
  val ts = s.tabs
  val () = s.tabs := TNil()
  val mark = pane_of(s.focus, s.active, s.righti)
  val ts2 = draw_tabrow(f, r, ts, tab_x0, mark, 0)
  val ts3 = draw_focus(f, r, ts2, s.active, ox, UI_TOPBAR_HEIGHT, half, isub(h, UI_TOPBAR_HEIGHT), lh, s.vault, s.cache, s.scratch, 0, s.viewmode)
  val ts4 = draw_right(f, r, ts3, s.split, s.righti, iadd(ox, half), UI_TOPBAR_HEIGHT, half, isub(h, UI_TOPBAR_HEIGHT), lh, s.vault, s.cache, s.scratch, s.viewmode)
  val ph = s.tabs
  val () = s.tabs := ts4
  val () = tabs_free(ph)
in
  if is_on(s.split) then ui_divider(r, iadd(ox, half), UI_TOPBAR_HEIGHT, isub(h, UI_TOPBAR_HEIGHT), Vertical) else ()
end

fun font_load_report(f: !Font, path: string): void =
  if font_use_file(f, path) then () else report_failure("font_load", path)

(* Klasor zaten varsa basarilidir; mkdir hatasi yalnizca klasor yoksa raporlanir. *)
fun ensure_dir_report(path: string): void =
  if path_is_dir(path) then ()
  else if ieq(fs_mkdir(path), 0) then ()
  else report_failure("vault_dir_create", path)

fun load_font_if_needed(f: !Font, s: &App_record): void =
  if ieq(s.font_idx, 0) andalso igt(buf_len(s.font_path), 0) then let
    val () = font_load_report(f, cstr(s.font_path))
    val () = font_set_px(f, s.fontpx)
    val () = s.font_idx := 1
  in
    ()
  end else ()

fun draw_panes(f: !Font, r: !Rend, a: !App, w: int, h: int): void =
  case+ a of
  | @APP(s) => let
      val () = load_font_if_needed(f, s)
      val sidew = if not(is_side_none(s.side)) then UI_SIDEBAR_WIDTH else 0
      val ox = sidew
      val pw = isub(w, sidew)
      val () = font_set_px(f, s.fontpx)
      val lh = font_line_h(f)
      val half = if is_on(s.split) then idiv(pw, 2) else pw
      val () = rend_rect(r, 0, 0, w, h, col_bg())
      val () = draw_topbar_chrome(f, r, s, w)
      val () = draw_editor_panes(f, r, s, ox, half, h, lh)
    in
      fold@(a)
    end

fun ui_draw_prompt(f: !Font, r: !Rend, a: !App): void =
  case+ a of
  | @APP(s) => let
      val () = draw_prompt(f, r, s.promptb, s.prompt)
    in
      fold@(a)
    end

fun draw_vault_item(f: !Font, r: !Rend, s: &App_record, mx: int, my: int, mw: int, vi: int): void = let
  var nbuf = buf_make(64)
  var pbuf = buf_make(256)
  val ry = iadd(my, iadd(68, imul(vi, 26)))
  val poff = buf_get32(s.vmeta, imul(vi, 4))
  val plen = buf_get32(s.vmeta, iadd(imul(vi, 4), 1))
  val noff = buf_get32(s.vmeta, iadd(imul(vi, 4), 2))
  val nlen = buf_get32(s.vmeta, iadd(imul(vi, 4), 3))
  val () = bcat(pbuf, s.vpaths, poff, iadd(poff, plen))
  val () = bcat(nbuf, s.vnames, noff, iadd(noff, nlen))
  val is_curr = ieq(c_strcmp(cstr(pbuf), cstr(s.vault)), 0)
  val is_hov = ige(s.hoverx, iadd(mx, 16)) andalso ilt(s.hoverx, isub(iadd(mx, mw), 16)) andalso ige(s.hovery, ry) andalso ilt(s.hovery, iadd(ry, 24))
  val () = ui_cell(f, r, iadd(mx, 16), ry, isub(mw, 32), 24, 0, Off, Off, UI_ICON_FOLDER, cstr(nbuf), cstr(pbuf), toggle_of(is_curr), toggle_of(is_hov))
  val () = buf_free(nbuf)
in
  buf_free(pbuf)
end

extern fun draw_vault_items_exh(f: !Font, r: !Rend, s: &App_record, mx: int, my: int, mw: int, vi: int, max_cnt: int): void = "mac#anth_die_void"

fun draw_vault_items_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, s: &App_record, mx: int, my: int, mw: int, vi: int, max_cnt: int): void =
  if recfuel > 0 then (
    if ige(vi, max_cnt) then ()
    else let
      val () = draw_vault_item(f, r, s, mx, my, mw, vi)
    in
      draw_vault_items_m(recfuel - 1, f, r, s, mx, my, mw, iadd(vi, 1), max_cnt)
    end
  ) else draw_vault_items_exh(f, r, s, mx, my, mw, vi, max_cnt)

fun draw_vault_items(f: !Font, r: !Rend, s: &App_record, mx: int, my: int, mw: int, vi: int, max_cnt: int): void = draw_vault_items_m(airlock_nat(MAX_REC_FUEL), f, r, s, mx, my, mw, vi, max_cnt)

fun draw_vault_dialog_body(f: !Font, r: !Rend, s: &App_record, mx: int, my: int, mw: int): void = let
  val () = draw_s(f, r, iadd(mx, 16), iadd(my, 44), "Mevcut kasalardan birini secin veya yeni kasa olusturun:", col_muted())
  val () = draw_vault_items(f, r, s, mx, my, mw, 0, imin(s.vcnt, 6))
  val iy = iadd(my, 248)
  val () = draw_s(f, r, iadd(mx, 16), iy, "Yeni Kasa Konumu (Klasor Yolu):", col_text())
  val qlen = buf_len(s.promptb)
  val () = ui_line_edit_draw(f, r, iadd(mx, 16), iadd(iy, 20), isub(mw, 32), 26, s.promptb, qlen, qlen, On, "ornegin: /home/kullanici/Notlar")
  val by = iadd(my, 310)
  val () = ui_button(f, r, iadd(mx, 16), by, 140, 30, "Ac / Olustur", Off, On)
in
  if igt(buf_len(s.vault), 0) then ui_button(f, r, isub(iadd(mx, mw), 116), by, 100, 30, "Iptal", Off, Off) else ()
end

fun draw_vault_select(f: !Font, r: !Rend, a: !App, w: int, h: int): void =
  case+ a of
  | @APP(s) => let
      val () = if is_on(s.vault_select) then let
        val () = rend_rect(r, 0, 0, w, h, col_overlay())
        val mw = 520
        val mh = 360
        val mx = idiv(isub(w, mw), 2)
        val my = idiv(isub(h, mh), 2)
        val () = ui_pane_begin(r, mx, my, mw, mh, col_bg())
        val () = ui_pane_draw_header(f, r, mx, my, mw, "Kasa Secimi / Vault Secimi", toggle_of(igt(buf_len(s.vault), 0)))
        val () = draw_vault_dialog_body(f, r, s, mx, my, mw)
      in
      end else ()
    in
      fold@(a)
    end

implement app_draw(a, f, r, w, h) = let
  val () = draw_panes(f, r, a, w, h)
  val show = let
    val v = case+ a of
      | @APP(s) => let val k = s.side in fold@(a); k end
  in
    v
  end
  val () = if not(is_side_none(show)) then draw_side(f, r, a, h) else ()
  val () = ui_draw_prompt(f, r, a)
  val () = ui_draw_menu(f, r, a)
in
  draw_vault_select(f, r, a, w, h)
end
extern fun find_wiki_exh(doc: !Doc, caret: int, k: int): int = "mac#anth_die_int"

fun find_wiki_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), doc: !Doc, caret: int, k: int): int =
  if recfuel > 0 then (
    if ige(k, doc_nnodes(doc)) then ~1
    else if ile(doc_node_start(doc, k), caret) andalso ilt(caret, doc_node_end(doc, k)) andalso is_kind(doc_node_kind(doc, k), KWiki) then k
    else find_wiki_m(recfuel - 1, doc, caret, iadd(k, 1))
  ) else find_wiki_exh(doc, caret, k)

fun find_wiki(doc: !Doc, caret: int, k: int): int = find_wiki_m(airlock_nat(MAX_REC_FUEL), doc, caret, k)

fun open_or(rest: Tabs, owned: Buf, go: Toggle): Tabs =
  if is_on(go) then tabs_open(rest, owned)
  else let
    val () = buf_free(owned)
  in
    rest
  end

fun take_if(doc: !Doc, w: int, rel: &Buf >> _, go: Toggle): void =
  if is_on(go) then take_path(doc, w, rel) else touchb(rel)

fun wiki_here(doc: !Doc, rest: Tabs, vault: !Buf): Tabs = let
  val () = seen_int(node_covering(doc, 0, 0, 0, 0, ~1))
  var rel = buf_make(8)
  var full = buf_make(8)
  var shown = buf_make(8)
  val w = find_wiki(doc, doc_caret(doc), 0)
  val () = take_if(doc, w, rel, toggle_of(ige(w, 0)))
  val () = resolve_path(vault, rel, full)
  val () = with_md(full, shown)
  val owned = bcopy(shown)
  val restw = open_or(rest, owned, toggle_of(ige(w, 0)))
  val () = buf_free(rel)
  val () = buf_free(full)
in
  let
    val () = buf_free(shown)
  in
    restw
  end
end

fun wiki_tab_here(doc: Doc, path: Buf, title: Buf, sc: int, rest: Tabs, vault: !Buf): Tabs = let
  val rest2 = wiki_here(doc, rest, vault)
in
  TCons(doc, path, title, sc, rest2)
end

extern fun wiki_open_exh(ts: Tabs, idx: int, vault: !Buf, i: int): Tabs = "mac#anth_die_box"

fun wiki_open_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int, vault: !Buf, i: int): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) =>
        if ieq(i, idx) then wiki_tab_here(doc, path, title, sc, rest, vault)
        else TCons(doc, path, title, sc, wiki_open_m(recfuel - 1, rest, idx, vault, iadd(i, 1)))
  ) else wiki_open_exh(ts, idx, vault, i)

fun wiki_open(ts: Tabs, idx: int, vault: !Buf, i: int): Tabs = wiki_open_m(airlock_nat(MAX_REC_FUEL), ts, idx, vault, i)

fun close_active_tab(ts: Tabs, idx: int): Tabs = let
  val ts2 = tabs_drop(ts, idx)
in
  if ieq(tabs_len(ts2), 0) then let
    val d = doc_open()
    var p = buf_make(4)
    var t = buf_make(16)
    val () = bstr(t, "Yeni Not")
  in
    tabs_add(ts2, d, p, t)
  end else ts2
end

fun new_empty_tab(ts: Tabs): Tabs = let
  val d = doc_open()
  var p = buf_make(4)
  var t = buf_make(16)
  val () = bstr(t, "Yeni Not")
in
  tabs_add(ts, d, p, t)
end

fun key_code_ctrl_char(c: Letter, sh: Toggle, ev: &event): Cmd =
  if is_letter(c, LZ) then (if is_on(sh) then CMD_REDO else CMD_UNDO)
  else if is_letter(c, LY) then CMD_REDO
  else if is_letter(c, LS) orelse is_letter(c, LSup) orelse ieq(x_key_is(ev, 15), 1) orelse ieq(x_key_is(ev, 20), 1) then CMD_SAVE
  else if is_letter(c, LA) then CMD_SELECT_ALL
  else if is_letter(c, LC) then CMD_COPY
  else if is_letter(c, LX) then CMD_CUT
  else if is_letter(c, LV) then CMD_PASTE
  else if is_letter(c, LF) orelse is_letter(c, LP) orelse is_letter(c, LO) then CMD_OPEN_SEARCH
  else if is_letter(c, LW) then CMD_CLOSE_TAB
  else if is_letter(c, LT) then CMD_NEW_TAB
  else if is_letter(c, LN) then (if is_on(sh) then CMD_NEW_FOLDER else CMD_NEW_FILE)
  else if is_letter(c, LE) then CMD_TOGGLE_VIEW
  else if is_letter(c, LB) then CMD_WRAP_BOLD
  else if is_letter(c, LI) then CMD_WRAP_ITALIC
  else if is_letter(c, LK) then CMD_WRAP_WIKILINK
  else CMD_NONE

fun key_code_ctrl_nav(ev: &event, sh: Toggle): Cmd =
  if key_is(ev, KeyLeft) then (if is_on(sh) then CMD_SELECT_WORD_LEFT else CMD_WORD_LEFT)
  else if key_is(ev, KeyRight) then (if is_on(sh) then CMD_SELECT_WORD_RIGHT else CMD_WORD_RIGHT)
  else if key_is(ev, KeyBackspace) then CMD_DELETE_WORD_LEFT
  else if key_is(ev, KeyDelete) then CMD_DELETE_WORD_RIGHT
  else if key_is(ev, KeyHome) then (if is_on(sh) then CMD_SELECT_DOC_START else CMD_DOC_START)
  else if key_is(ev, KeyEnd) then (if is_on(sh) then CMD_SELECT_DOC_END else CMD_DOC_END)
  else if key_is(ev, KeyTab) then (if is_on(sh) then CMD_PREV_TAB else CMD_NEXT_TAB)
  else key_code_ctrl_char(letter_of(key_char(ev)), sh, ev)

fun key_code_non_ctrl(ev: &event, sh: Toggle): Cmd =
  if key_is(ev, KeyEscape) then CMD_ESCAPE
  else if key_is(ev, KeyLeft) then (if is_on(sh) then CMD_SELECT_LEFT else CMD_CARET_LEFT)
  else if key_is(ev, KeyRight) then (if is_on(sh) then CMD_SELECT_RIGHT else CMD_CARET_RIGHT)
  else if key_is(ev, KeyUp) then (if is_on(sh) then CMD_SELECT_UP else CMD_CARET_UP)
  else if key_is(ev, KeyDown) then (if is_on(sh) then CMD_SELECT_DOWN else CMD_CARET_DOWN)
  else if key_is(ev, KeyHome) then (if is_on(sh) then CMD_SELECT_LINE_START else CMD_CARET_LINE_START)
  else if key_is(ev, KeyEnd) then (if is_on(sh) then CMD_SELECT_LINE_END else CMD_CARET_LINE_END)
  else if key_is(ev, KeyPageUp) then (if is_on(sh) then CMD_SELECT_PAGE_UP else CMD_PAGE_UP)
  else if key_is(ev, KeyPageDown) then (if is_on(sh) then CMD_SELECT_PAGE_DOWN else CMD_PAGE_DOWN)
  else if key_is(ev, KeyBackspace) then CMD_BACKSPACE
  else if key_is(ev, KeyDelete) then CMD_DELETE
  else if key_is(ev, KeyReturn) then CMD_NEWLINE
  else if key_is(ev, KeyTab) then CMD_INDENT
  else CMD_TEXT_INPUT

fun key_code(ev: &event, act: Toggle): Cmd =
  if is_off(act) then (if key_is(ev, KeyEscape) then CMD_ESCAPE else CMD_NONE)
  else if ctrl_on(ev) then key_code_ctrl_nav(ev, toggle_of(shift_on(ev)))
  else key_code_non_ctrl(ev, toggle_of(shift_on(ev)))

fun is_modifying_cmd(cmd: Cmd): bool =
  is_cmd(cmd, CMD_BACKSPACE) orelse is_cmd(cmd, CMD_DELETE) orelse is_cmd(cmd, CMD_DELETE_SELECTION)
     orelse is_cmd(cmd, CMD_UNDO) orelse is_cmd(cmd, CMD_REDO)
     orelse is_cmd(cmd, CMD_WRAP_BOLD) orelse is_cmd(cmd, CMD_WRAP_ITALIC) orelse is_cmd(cmd, CMD_WRAP_WIKILINK)
     orelse is_cmd(cmd, CMD_INDENT) orelse is_cmd(cmd, CMD_DELETE_WORD_LEFT) orelse is_cmd(cmd, CMD_DELETE_WORD_RIGHT)

fun apply_key_copy(ts: Tabs, idx: int, clip: &Buf >> _, p: !Plat): Tabs = let
  val () = tabs_copy(ts, idx, clip)
  val () = plat_own(p, false)
  val () = plat_own(p, true)
in
  ts
end

fun apply_key_cut(ts: Tabs, idx: int, clip: &Buf >> _, p: !Plat): Tabs = let
  val ts1 = apply_key_copy(ts, idx, clip, p)
  val ts2 = tabs_cmd(ts1, idx, CMD_DELETE_SELECTION)
  val () = tabs_sync_vfs(ts2, idx)
in
  ts2
end

fun apply_key_paste(ts: Tabs, paste: &Toggle >> _, p: !Plat): Tabs = let
  val () = paste := On
  val () = plat_paste(p, false)
in
  ts
end

fun apply_key_newline(ts: Tabs, idx: int, scratch: &Buf >> _): Tabs = let
  val () = buf_set(scratch, 0, 10)
  val ts2 = tabs_ins_buf(ts, idx, scratch, 1)
  val () = tabs_sync_vfs(ts2, idx)
in
  ts2
end

fun apply_key_command(ts: Tabs, idx: int, cmd: Cmd): Tabs = let
  val ts2 = tabs_cmd(ts, idx, cmd)
  val () = if is_modifying_cmd(cmd) then tabs_sync_vfs(ts2, idx) else ()
in
  ts2
end

fun apply_key(ts: Tabs, idx: int, cmd: Cmd, vault: !Buf, clip: &Buf >> _, scratch: &Buf >> _, p: !Plat, paste: &Toggle >> _): Tabs =
  if is_cmd(cmd, CMD_SAVE) then tabs_ensure_paths(ts, vault)
  else if is_cmd(cmd, CMD_COPY) then apply_key_copy(ts, idx, clip, p)
  else if is_cmd(cmd, CMD_CUT) then apply_key_cut(ts, idx, clip, p)
  else if is_cmd(cmd, CMD_PASTE) then apply_key_paste(ts, paste, p)
  else if is_cmd(cmd, CMD_NEWLINE) then apply_key_newline(ts, idx, scratch)
  else if is_cmd(cmd, CMD_ESCAPE) then tabs_cmd(ts, idx, CMD_COLLAPSE_SELECTION)
  else if not(is_cmd(cmd, CMD_NONE)) then apply_key_command(ts, idx, cmd)
  else ts

fun key_dispatch(ts: Tabs, idx: int, cmd: Cmd, vault: !Buf, clip: &Buf >> _, scratch: &Buf >> _, p: !Plat, paste: &Toggle >> _, ev: &event): Tabs =
  if is_cmd(cmd, CMD_TEXT_INPUT) then
    if ctrl_on(ev) then ts
    else let
      val cap = buf_cap(scratch)
      val raw_n = ev_text_buf(ev, scratch, cap)
      val n = filter_text(scratch, raw_n)
    in
      if igt(n, 0) then let
        val ts2 = tabs_ins_buf(ts, idx, scratch, n)
        val () = tabs_sync_vfs(ts2, idx)
      in
        ts2
      end else ts
    end
  else apply_key(ts, idx, cmd, vault, clip, scratch, p, paste)

fun row_if(tree: !Buf, meta: !Buf, sel: int, cur: &Buf >> _, go: Toggle): void =
  if is_on(go) then row_path(tree, meta, sel, cur) else touchb(cur)

fun fill_dir_cwd(dir: &Buf >> _): void = let
  var cwd_buf = buf_make(512)
  val () = seen_int(c_cwd_buf(cwd_buf, 511))
  val () = bstr(dir, buf_cstr(cwd_buf))
in
  buf_free(cwd_buf)
end

fun fill_dir_from_dirname(dir: &Buf >> _, cur: !Buf, vault: !Buf): void = let
  val () = dirname_of(cur, dir)
  val () = if ieq(buf_len(dir), 0) andalso igt(buf_len(vault), 0) then bcat(dir, vault, 0, buf_len(vault)) else ()
in
end

fun fill_dir_vault_or_cwd(dir: &Buf >> _, vault: !Buf): void = let
  val n = buf_len(vault)
in
  if igt(n, 0) then bcat(dir, vault, 0, n) else fill_dir_cwd(dir)
end

fun fill_dir(dir: &Buf >> _, cur: !Buf, vault: !Buf, use_dir: Toggle, sel: int): void =
  if is_on(use_dir) andalso igt(buf_len(cur), 0) then let
    val n = buf_len(cur)
  in
    bcat(dir, cur, 0, n)
  end else if ige(sel, 0) andalso igt(buf_len(cur), 0) then fill_dir_from_dirname(dir, cur, vault)
  else let
    val () = seen_buf(cur)
  in
    fill_dir_vault_or_cwd(dir, vault)
  end

fun copy_if(ts: !Tabs, idx: int, clip: &Buf >> _, go: Toggle): void =
  if is_on(go) then tabs_copy(ts, idx, clip) else touchb(clip)

fun cmd_if(ts: Tabs, idx: int, cmd: Cmd, go: Toggle): Tabs =
  if is_on(go) then tabs_cmd(ts, idx, cmd) else ts

fun drop_if(ts: Tabs, ti: int, go: Toggle): Tabs =
  if is_on(go) then tabs_drop(ts, ti) else ts

fun tab_keep_one(ts: Tabs, close: Toggle): Tabs =
  if is_on(close) then
    if ieq(tabs_len(ts), 0) then new_empty_tab(ts) else ts
  else ts

fun open_row(ts: Tabs, tree: !Buf, meta: !Buf, row: int, go: Toggle): Tabs =
  if is_on(go) then let
    var cur = buf_make(8)
    val () = row_path(tree, meta, row, cur)
    val owned = bcopy(cur)
    val () = buf_free(cur)
  in
    tabs_open(ts, owned)
  end else ts

fun click_go(f: !Font, r: !Rend, ts: Tabs, idx: int, x: int, y: int, ox: int, pw: int, lh: int, scratch: &Buf >> _, keep: Toggle, hitk: &NodeKind >> _, hiti: &int >> _, go: Toggle): Tabs =
  if is_on(go) then tabs_click(f, r, ts, idx, x, y, ox, pw, 0, lh, scratch, keep, hitk, hiti, 0)
  else let
    val () = touchb(scratch)
  in
    ts
  end

fun wiki_go(ts: Tabs, idx: int, vault: !Buf, go: Toggle): Tabs =
  if is_on(go) then wiki_open(ts, idx, vault, 0) else ts

fun read_all(path: !Buf, dst: &Buf >> _): void = let
  val p = cstr(path)
  val sz = fs_size(p)
in
  if sz <= 0 orelse sz > 8000000 then touchb(dst)
  else let
    val fd = fs_open_read(p)
    val () = bclear(dst)
    val () = buf_ensure(dst, iadd(sz, 1))
    val n = read_or(dst, fd, sz)
    val () = if fd >= 0 then fs_close(fd) else ()
  in
    buf_set_len(dst, if igt(n, 0) then n else 0)
  end
end

fun fill_node_path(doc: !Doc, ni: int, vault: !Buf, dst: &Buf >> _): void = let
  var rel = buf_make(64)
  var full = buf_make(160)
  val () = take_if(doc, ni, rel, toggle_of(ige(ni, 0)))
  val () = resolve_path(vault, rel, full)
  val () = with_md(full, dst)
  val () = buf_free(rel)
in
  buf_free(full)
end

fun copy_node_here(doc: !Doc, ni: int, vault: !Buf, clip: &Buf >> _): void = let
  var shown = buf_make(160)
  val () = fill_node_path(doc, ni, vault, shown)
  val () = read_all(shown, clip)
in
  buf_free(shown)
end

extern fun copy_node_file_exh(ts: !Tabs, idx: int, ni: int, vault: !Buf, clip: &Buf >> _, i: int): void = "mac#anth_die_void"

fun copy_node_file_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: !Tabs, idx: int, ni: int, vault: !Buf, clip: &Buf >> _, i: int): void =
  if recfuel > 0 then (
    case+ ts of
    | @TNil() => let
        val () = touchb(clip)
      in
        fold@(ts)
      end
    | @TCons(doc, path, title, sc, rest) => let
        val () = if ieq(i, idx) then copy_node_here(doc, ni, vault, clip)
                 else copy_node_file_m(recfuel - 1, rest, idx, ni, vault, clip, iadd(i, 1))
        val () = seen_buf(path)
        val () = seen_buf(title)
        val () = seen_int(sc)
      in
        fold@(ts)
      end
  ) else copy_node_file_exh(ts, idx, ni, vault, clip, i)

fun copy_node_file(ts: !Tabs, idx: int, ni: int, vault: !Buf, clip: &Buf >> _, i: int): void = copy_node_file_m(airlock_nat(MAX_REC_FUEL), ts, idx, ni, vault, clip, i)

fun clip_image(ts: !Tabs, idx: int, ni: int, vault: !Buf, clip: &Buf >> _, go: Toggle): void =
  if is_on(go) then copy_node_file(ts, idx, ni, vault, clip, 0) else touchb(clip)

fun erase_span(doc: !Doc, a: int, b: int): void = let
  val () = doc_set_caret_move(doc, a)
  val () = doc_set_caret_extend(doc, b)
in
  doc_delete(doc)
end

fun span_if(doc: !Doc, a: int, b: int, go: Toggle): void =
  if is_on(go) then erase_span(doc, a, b)
  else let
    val () = doc_touch(doc)
  in
    ()
  end

fun node_field(doc: !Doc, ni: int, field: int): int =
  if ige(ni, 0) then doc_get(doc, ni, field)
  else let
    val () = doc_touch(doc)
  in
    0
  end

extern fun del_node_exh(ts: Tabs, idx: int, ni: int): Tabs = "mac#anth_die_box"

fun del_node_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int, ni: int): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val a = node_field(doc, ni, 1)
        val b = node_field(doc, ni, 2)
        val go = ieq(idx, 0) andalso ige(ni, 0)
        val () = span_if(doc, a, b, toggle_of(go))
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc, rest) else TCons(doc, path, title, sc, del_node_m(recfuel - 1, rest, isub(idx, 1), ni))
      end
  ) else del_node_exh(ts, idx, ni)

fun del_node(ts: Tabs, idx: int, ni: int): Tabs = del_node_m(airlock_nat(MAX_REC_FUEL), ts, idx, ni)

fun del_go(ts: Tabs, idx: int, ni: int, go: Toggle): Tabs =
  if is_on(go) then del_node(ts, idx, ni) else ts

extern fun strip_into_exh(src: !Buf, dst: &Buf >> _, i: int): void = "mac#anth_die_void"

fun strip_into_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, dst: &Buf >> _, i: int): void =
  if recfuel > 0 then (
    if ige(i, buf_len(src)) then touchb(dst)
    else let
      val c = buf_get(src, i)
      val drop = ieq(c, 42) orelse ieq(c, 61) orelse ieq(c, 91) orelse ieq(c, 93) orelse ieq(c, 96)
      val () = push_if(dst, toggle_of(not(drop)), c)
    in
      strip_into_m(recfuel - 1, src, dst, iadd(i, 1))
    end
  ) else strip_into_exh(src, dst, i)

fun strip_into(src: !Buf, dst: &Buf >> _, i: int): void = strip_into_m(airlock_nat(MAX_REC_FUEL), src, dst, i)

fun clear_span_stripped(doc: !Doc, lo: int, hi: int): void = let
  var raw = buf_make(iadd(isub(hi, lo), 2))
  var out = buf_make(iadd(isub(hi, lo), 2))
  val cap = buf_cap(raw)
  val n = doc_slice_buf(doc, lo, hi, raw, cap)
  val () = buf_set_len(raw, n)
  val () = strip_into(raw, out, 0)
  val () = erase_span(doc, lo, hi)
  val m = buf_len(out)
  val () = doc_insert_buf(doc, out, m)
  val () = buf_free(raw)
in
  buf_free(out)
end

fun clear_doc(doc: !Doc): void = let
  val a0 = doc_anchor(doc)
  val c0 = doc_caret(doc)
  val lo = imin(a0, c0)
  val hi = imax(a0, c0)
in
  if ieq(lo, hi) then let
    val () = doc_touch(doc)
  in
    ()
  end else clear_span_stripped(doc, lo, hi)
end

extern fun clear_node_exh(ts: Tabs, idx: int): Tabs = "mac#anth_die_box"

fun clear_node_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = if ieq(idx, 0) then clear_doc(doc) else let
          val () = doc_touch(doc)
        in
          ()
        end
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc, rest) else TCons(doc, path, title, sc, clear_node_m(recfuel - 1, rest, isub(idx, 1)))
      end
  ) else clear_node_exh(ts, idx)

fun clear_node(ts: Tabs, idx: int): Tabs = clear_node_m(airlock_nat(MAX_REC_FUEL), ts, idx)

fun clear_go(ts: Tabs, idx: int, go: Toggle): Tabs =
  if is_on(go) then clear_node(ts, idx) else ts

fun toggle_go(ts: Tabs, idx: int, ni: int, go: Toggle): Tabs =
  if is_on(go) then tabs_toggle(ts, idx, ni) else ts

fun toggle_task_go(ts: Tabs, idx: int, ni: int, go: Toggle): Tabs =
  if is_on(go) then let
    val ts2 = tabs_toggle_task(ts, idx, ni)
    val () = tabs_sync_vfs(ts2, idx)
  in
    ts2
  end else ts

fun open_hit(ts: Tabs, hmeta: !Buf, hits: !Buf, srow: int, go: Toggle): Tabs =
  if is_on(go) then let
    var hitfile = buf_make(16)
    val () = find_hit_file(hmeta, hits, srow, hitfile)
    val owned = bcopy(hitfile)
    val () = buf_free(hitfile)
  in
    tabs_open(ts, owned)
  end else ts

fun open_created_file(ts: Tabs, dir: !Buf, name: !Buf, kind: PromptKind): Tabs =
  if is_prompt_newfile(kind) then let
    var new_file = buf_make(8)
    val () = child_path(dir, name, new_file)
    val has_dot = has_dot_char(name, 0)
    val need_md = not(has_dot)
    val () = bstr_if(new_file, toggle_of(need_md), ".md")
  in
    tabs_open(ts, new_file)
  end else ts

fun apply_tab_cmd(ts: Tabs, cmd: Cmd, idx: int): Tabs =
  if is_cmd(cmd, CMD_CLOSE_TAB) then close_active_tab(ts, idx)
  else if is_cmd(cmd, CMD_NEW_TAB) then new_empty_tab(ts)
  else ts

fun hit_open_if(ts: Tabs, hmeta: !Buf, hits: !Buf, hn: int, qf: Toggle, qr: EditResult): Tabs =
  if is_on(qf) andalso is_edit_submit(qr) andalso igt(hn, 0) then open_hit(ts, hmeta, hits, 0, On) else ts

fun handle_vault_select_key(s: &App_record >> _, ev: &event): void = let
  val vr = edit_line(s.promptb, ev, s.scratch)
in
  if is_edit_submit(vr) andalso igt(buf_len(s.promptb), 0) then let
    val target = cstr(s.promptb)
    val () = ensure_dir_report(target)
    val () = switch_to_vault(s, target)
  in
  end else if is_edit_cancel(vr) andalso igt(buf_len(s.vault), 0) then s.vault_select := Off
  else ()
end

fun prompt_fill_paths(s: &App_record, dir: &Buf >> _, cur: &Buf >> _): void = let
  val sel_valid = ige(s.sel, 0) andalso ilt(s.sel, s.tn)
  val () = row_if(s.tree, s.tmeta, s.sel, cur, toggle_of(sel_valid))
  val use_dir = sel_valid andalso is_dir_mark(meta_dir(s.tmeta, s.sel), DirYes)
  val () = fill_dir(dir, cur, s.vault, toggle_of(use_dir), if sel_valid then s.sel else ~1)
in
end

fun submit_open_new_file(s: &App_record >> _, dir: !Buf, prompt_kind: PromptKind): void = let
  val ts_curr = s.tabs
  val () = s.tabs := TNil()
  val ts_next = open_created_file(ts_curr, dir, s.promptb, prompt_kind)
  val ph = s.tabs
  val () = s.tabs := ts_next
  val () = tabs_free(ph)
in
end

fun prompt_reset(s: &App_record >> _): void = let
  val () = s.prompt := PromptNone
in
  bclear(s.promptb)
end

fun handle_prompt_submission(s: &App_record >> _, pr: EditResult): void =
  if is_edit_submit(pr) andalso igt(buf_len(s.promptb), 0) then let
    var dir = buf_make(8)
    var cur = buf_make(8)
    val () = prompt_fill_paths(s, dir, cur)
    val prompt_kind = s.prompt
    val () = act_prompt(dir, cur, s.promptb, prompt_kind)
    val () = submit_open_new_file(s, dir, prompt_kind)
    val () = if is_prompt_newfile(prompt_kind) then s.active := 0 else ()
    val () = s.prompt := PromptNone
    val () = bclear(s.promptb)
    val () = s.treedirty := On
    val () = buf_free(dir)
  in
    buf_free(cur)
  end else if is_edit_submit(pr) orelse is_edit_cancel(pr) then prompt_reset(s)
  else ()

fun open_search_panel(s: &App_record >> _): void = let
  val () = s.side := SideSearch
  val () = s.qfocus := On
in
  bclear(s.query)
end

fun begin_prompt(s: &App_record >> _, kind: PromptKind): void = let
  val () = s.prompt := kind
in
  bclear(s.promptb)
end

fun toggle_view_mode(s: &App_record >> _): void = let
  val vm = if is_view_edit(s.viewmode) then ViewRead else ViewEdit
  val () = s.viewmode := vm
in
  save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
end

fun escape_sidebar_state(s: &App_record >> _): void = let
  val () = s.menu := MenuNone
  val () = s.qfocus := Off
  val () = s.prompt := PromptNone
in
  bclear(s.promptb)
end

fun handle_sidebar_shortcut_cmd(s: &App_record >> _, cmd: Cmd): void =
  if is_cmd(cmd, CMD_OPEN_SEARCH) then open_search_panel(s)
  else if is_cmd(cmd, CMD_NEW_FILE) then begin_prompt(s, PromptNewFile)
  else if is_cmd(cmd, CMD_NEW_FOLDER) then begin_prompt(s, PromptNewFolder)
  else if is_cmd(cmd, CMD_TOGGLE_VIEW) then toggle_view_mode(s)
  else if is_cmd(cmd, CMD_ESCAPE) then escape_sidebar_state(s)
  else ()

fun tab_select_close_or_new(s: &App_record >> _, cmd: Cmd, ts_inter: !Tabs): void = let
  val max_i = isub(tabs_len(ts_inter), 1)
  val () = if is_cmd(cmd, CMD_NEW_TAB) then s.active := max_i
           else s.active := imax(0, imin(max_i, s.active))
  val () = s.righti := imax(0, imin(max_i, s.righti))
in
  save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
end

fun tab_cycle_next(s: &App_record >> _, ts_inter: !Tabs): void = let
  val ntabs = tabs_len(ts_inter)
in
  if igt(ntabs, 1) then let
    val next_i = iadd(s.active, 1)
    val cur_i = if ige(next_i, ntabs) then 0 else next_i
    val () = s.active := cur_i
  in
    save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
  end else ()
end

fun tab_cycle_prev(s: &App_record >> _, ts_inter: !Tabs): void = let
  val ntabs = tabs_len(ts_inter)
in
  if igt(ntabs, 1) then let
    val prev_i = isub(s.active, 1)
    val cur_i = if ilt(prev_i, 0) then isub(ntabs, 1) else prev_i
    val () = s.active := cur_i
  in
    save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
  end else ()
end

fun handle_tab_nav_cmd(s: &App_record >> _, cmd: Cmd, ts_inter: !Tabs): void =
  if is_cmd(cmd, CMD_CLOSE_TAB) orelse is_cmd(cmd, CMD_NEW_TAB) then tab_select_close_or_new(s, cmd, ts_inter)
  else if is_cmd(cmd, CMD_NEXT_TAB) then tab_cycle_next(s, ts_inter)
  else if is_cmd(cmd, CMD_PREV_TAB) then tab_cycle_prev(s, ts_inter)
  else ()

fun search_query_edit(s: &App_record >> _, qr: EditResult): void = let
  val () = if is_on(s.qfocus) andalso is_edit_none(qr) then refresh_search(s.vault, s.query, s.hits, s.hmeta, s.hn) else ()
  val () = if is_on(s.qfocus) andalso is_edit_cancel(qr) then s.qfocus := Off else ()
in
end

fun search_hit_focus(s: &App_record >> _): void = let
  val () = s.qfocus := Off
  val () = s.active := 0
in
  save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
end

fun key_tabs_step(s: &App_record >> _, p: !Plat, ev: &event, cmd: Cmd, hit_go: Toggle): void = let
  val ts0 = s.tabs
  val () = s.tabs := TNil()
  val ts = hit_open_if(ts0, s.hmeta, s.hits, s.hn, toggle_of(is_on(hit_go)), EditSubmit)
  val idx = pane_of(s.focus, s.active, s.righti)
  var ts_inter: Tabs = apply_tab_cmd(ts, cmd, idx)
  val () = handle_tab_nav_cmd(s, cmd, ts_inter)
  val ts2 = key_dispatch(ts_inter, idx, cmd, s.vault, s.clip, s.scratch, p, s.paste, ev)
  val ph = s.tabs
  val () = s.tabs := ts2
  val () = tabs_free(ph)
in
end

fun key_editor_step(s: &App_record >> _, p: !Plat, f: !Font, ev: &event): void = let
  val act = is_prompt_none(s.prompt) andalso is_off(s.qfocus)
  val pr = if not(is_prompt_none(s.prompt)) then edit_line(s.promptb, ev, s.scratch) else EditNone
  val qr = if is_on(s.qfocus) andalso is_prompt_none(s.prompt) then edit_line(s.query, ev, s.scratch) else EditNone
  val () = search_query_edit(s, qr)
  val hit_go = is_on(s.qfocus) andalso is_edit_submit(qr) andalso igt(s.hn, 0)
  val () = if hit_go then search_hit_focus(s) else ()
  val () = handle_prompt_submission(s, pr)
  val cmd = key_code(ev, toggle_of(act))
  val () = handle_sidebar_shortcut_cmd(s, cmd)
  val () = key_tabs_step(s, p, ev, cmd, toggle_of(hit_go))
  val () = if is_cmd(cmd, CMD_SAVE) then let
      val () = s.treedirty := On
      val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
    in
    end else ()
  val () = seen_int(font_line_h(f))
in
end

fun on_key(a: !App, p: !Plat, f: !Font, ev: &event): void =
  case+ a of
  | @APP(s) =>
      if is_on(s.vault_select) then let
        val () = handle_vault_select_key(s, ev)
      in
        fold@(a)
      end else let
        val () = key_editor_step(s, p, f, ev)
      in
        fold@(a)
      end
fun select_vault_row(s: &App_record >> _, vi: int): void =
  if ige(vi, 0) andalso ilt(vi, s.vcnt) then let
    val poff = buf_get32(s.vmeta, imul(vi, 4))
    val plen = buf_get32(s.vmeta, iadd(imul(vi, 4), 1))
    var pbuf = buf_make(256)
    val () = bcat(pbuf, s.vpaths, poff, iadd(poff, plen))
    val target = cstr(pbuf)
    val () = switch_to_vault(s, target)
    val () = buf_free(pbuf)
  in
  end else ()

fun vault_open_from_prompt(s: &App_record >> _): void = let
  val target = cstr(s.promptb)
  val () = ensure_dir_report(target)
in
  switch_to_vault(s, target)
end

fun handle_vault_select_click(s: &App_record >> _, x: int, y: int, w: int, h: int): void = let
  val mw = 520
  val mh = 360
  val mx = idiv(isub(w, mw), 2)
  val my = idiv(isub(h, mh), 2)
  val in_list_y = ige(y, iadd(my, 74)) andalso ilt(y, iadd(my, iadd(74, imul(imin(s.vcnt, 6), 28))))
  val in_list_x = ige(x, iadd(mx, 16)) andalso ilt(x, isub(iadd(mx, mw), 16))
  val () = if in_list_x andalso in_list_y then select_vault_row(s, idiv(isub(y, iadd(my, 74)), 28)) else ()
  val on_open_btn = ige(x, iadd(mx, 16)) andalso ilt(x, iadd(mx, 156)) andalso ige(y, iadd(my, 312)) andalso ilt(y, iadd(my, 342))
  val () = if on_open_btn andalso igt(buf_len(s.promptb), 0) then vault_open_from_prompt(s) else ()
  val on_cancel_btn = ige(x, isub(iadd(mx, mw), 116)) andalso ilt(x, isub(iadd(mx, mw), 16)) andalso ige(y, iadd(my, 312)) andalso ilt(y, iadd(my, 342))
  val () = if on_cancel_btn andalso igt(buf_len(s.vault), 0) then let
    val () = s.vault_select := Off
  in
  end else ()
in
end

fun handle_context_menu_action(s: &App_record >> _, inside: Toggle, item: int): void =
  if is_on(inside) andalso is_menu_filetree(s.menu) then (
    if ieq(item, tree_row(TreeNewFile)) then s.prompt := PromptNewFile
    else if ieq(item, tree_row(TreeNewFolder)) then s.prompt := PromptNewFolder
    else if ieq(item, tree_row(TreeRename)) then s.prompt := PromptRename
    else if ieq(item, tree_row(TreeDelete)) andalso ige(s.sel, 0) then let
      var cur = buf_make(8)
      val () = row_path(s.tree, s.tmeta, s.sel, cur)
      val () = do_delete(cur)
      val () = s.treedirty := On
    in
      buf_free(cur)
    end else ()
  ) else ()

fun topbar_toggle_view(s: &App_record >> _): void = let
  val () = s.viewmode := (if is_view_edit(s.viewmode) then ViewRead else ViewEdit)
in
  save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
end

fun topbar_toggle_files(s: &App_record >> _): void = let
  val () = s.side := (if is_side_files(s.side) then SideNone else SideFiles)
  val () = s.qfocus := Off
in
end

fun topbar_toggle_search(s: &App_record >> _): void = let
  val () = s.side := (if is_side_search(s.side) then SideNone else SideSearch)
  val () = s.qfocus := toggle_of(is_side_search(s.side))
in
end

fun topbar_toggle_config(s: &App_record >> _): void = let
  val () = s.side := (if is_side_config(s.side) then SideNone else SideConfig)
  val () = s.qfocus := Off
in
end

fun handle_topbar_action(s: &App_record >> _, w: int, x: int): void = let
  val top_w = UI_TOPBAR_BTN_WIDTH
  val x1 = topbar_btn_x(0)
  val x2 = topbar_btn_x(1)
  val x3 = topbar_btn_x(2)
  val bx = topbar_mode_btn_x(w)
in
  if ige(x, bx) andalso ilt(x, iadd(bx, top_w)) then topbar_toggle_view(s)
  else if ige(x, x1) andalso ilt(x, iadd(x1, top_w)) then topbar_toggle_files(s)
  else if ige(x, x2) andalso ilt(x, iadd(x2, top_w)) then topbar_toggle_search(s)
  else if ige(x, x3) andalso ilt(x, iadd(x3, top_w)) then topbar_toggle_config(s)
  else ()
end

fun config_cycle_font_px(s: &App_record >> _): void = let
  val nxtpx = if ieq(s.fontpx, 16) then 18 else if ieq(s.fontpx, 18) then 20 else 16
  val () = s.fontpx := nxtpx
in
  save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
end

fun config_select_font(s: &App_record >> _, f: !Font, sel_fi: int): void =
  if ige(sel_fi, 0) andalso ilt(sel_fi, s.fcnt) then let
    val poff = buf_get32(s.fmeta, imul(sel_fi, 4))
    val plen = buf_get32(s.fmeta, iadd(imul(sel_fi, 4), 1))
    val () = bclear(s.font_path)
    val () = bcat(s.font_path, s.fpaths, poff, iadd(poff, plen))
    val () = font_load_report(f, cstr(s.font_path))
    val () = font_set_px(f, s.fontpx)
    val () = s.font_idx := 1
    val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
  in
    ()
  end else ()

fun handle_sidebar_config_action(s: &App_record >> _, f: !Font, x: int, y: int): void = let
  val on_kasa_btn = ige(x, 12) andalso ilt(x, 162) andalso ige(y, 122) andalso ilt(y, 144)
  val on_font_px = igt(y, 148) andalso ilt(y, 175)
  val max_fi = imin(s.fcnt, 12)
  val on_font_list = ige(y, 205) andalso ilt(y, iadd(210, imul(max_fi, 22)))
in
  if on_kasa_btn then (
    conf_list_vaults(s.vpaths, s.vnames, s.vmeta, s.vcnt);
    s.vault_select := On
  )
  else if on_font_px then config_cycle_font_px(s)
  else if on_font_list then config_select_font(s, f, idiv(isub(y, 205), 22))
  else ()
end

fun editor_wiki_focus(s: &App_record >> _): void = let
  val () = s.active := 0
in
  save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
end

fun editor_click_hit(f: !Font, r: !Rend, s: &App_record >> _, ts: Tabs, ev: &event, x: int, y: int, ox: int, half: int, idx2: int, editor: Toggle): Tabs = let
  val keep = iand(ev_mods(ev), mod_shift()) <> 0
  val () = font_set_px(f, s.fontpx)
  val ts4 = click_go(f, r, ts, idx2, x, y, ox, half, font_line_h(f), s.scratch, toggle_of(keep), s.hitk, s.hiti, editor)
  val colx_hit = column_x(ox, half)
  val on_arrow = is_on(editor) andalso ige(x, isub(colx_hit, 24)) andalso ilt(x, colx_hit) andalso ige(s.hiti, 0)
  val on_task = is_on(editor) andalso is_kind(s.hitk, KTask) andalso ige(x, colx_hit) andalso ilt(x, iadd(colx_hit, 36)) andalso ige(s.hiti, 0)
  val ts4_a = toggle_go(ts4, idx2, s.hiti, toggle_of(on_arrow))
  val ts4_b = toggle_task_go(ts4_a, idx2, s.hiti, toggle_of(on_task))
in
  ts4_b
end

fun handle_editor_click(s: &App_record >> _, f: !Font, r: !Rend, ts: Tabs, ev: &event,
                        x: int, y: int, w: int, sidew: int, skip: Toggle, onbar: Toggle, onside: Toggle,
                        button: Btn, idx: int, imgdel: Toggle, clear: Toggle): Tabs = let
  val pw0 = isub(w, sidew)
  val half = if is_on(s.split) then idiv(pw0, 2) else pw0
  val editor = is_off(skip) andalso is_off(onbar) andalso is_off(onside) andalso is_btn(button, BtnLeft)
  val foc = editor andalso is_on(s.split) andalso ige(x, iadd(sidew, half))
  val () = if editor then s.focus := toggle_of(foc) else ()
  val ox = if is_on(s.focus) then iadd(sidew, half) else sidew
  val idx2 = pane_of(s.focus, s.active, s.righti)
  val ts4 = editor_click_hit(f, r, s, ts, ev, x, y, ox, half, idx2, toggle_of(editor))
  val gowiki = editor andalso ctrl_on(ev)
  val ts5 = wiki_go(ts4, idx2, s.vault, toggle_of(gowiki))
  val ts6 = del_go(ts5, idx, s.hiti, toggle_of(is_on(imgdel)))
  val ts7 = clear_go(ts6, idx, toggle_of(is_on(clear)))
  val () = if gowiki then editor_wiki_focus(s) else ()
  val () = if editor then s.qfocus := Off else ()
in
  ts7
end

fun down_pick_tab(s: &App_record >> _, x: int, ti: int): void = let
  val () = s.drag := DragNone
  val () = s.dragi := ti
  val () = s.downx := x
  val () = s.downy := s.downy
  val () = s.active := ti
  val () = s.focus := Off
in
  save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
end

fun handle_down_tab_bar_selection(
  s: &App_record >> _, ts: !Tabs, f: !Font, r: !Rend,
  onbar: Toggle, skip: Toggle, x: int, tab_x0: int, bx: int,
  ti: &int >> _, close: &bool >> _
): void = let
  val () = if is_on(onbar) andalso is_off(skip) andalso ige(x, tab_x0) andalso ilt(x, bx) then
    tab_hit_test(f, r, ts, tab_x0, x, ti, close)
  else ()
  val ntabs = tabs_len(ts)
  val pick = is_on(onbar) andalso is_off(skip) andalso ige(ti, 0) andalso ilt(ti, ntabs) andalso not(close)
in
  if pick then down_pick_tab(s, x, ti) else ()
end

fun text_item_hit(s: &App_record, skip: Toggle, inside: Toggle, item: int, which: TextItem): bool =
  is_on(skip) andalso is_on(inside) andalso is_menu_text(s.menu) andalso ieq(item, text_row(which))

fun image_item_hit(s: &App_record, skip: Toggle, inside: Toggle, item: int, which: ImageItem): bool =
  is_on(skip) andalso is_on(inside) andalso is_menu_image(s.menu) andalso ieq(item, image_row(which))

fun down_menu_clip(s: &App_record >> _, p: !Plat, ts0: !Tabs, idx: int, cut: Toggle, copy: Toggle, imgcopy: Toggle, paste: Toggle, imgrev: Toggle): void = let
  val () = copy_if(ts0, idx, s.clip, toggle_of(is_on(cut) orelse is_on(copy)))
  val () = clip_image(ts0, idx, s.hiti, s.vault, s.clip, imgcopy)
  val own = is_on(cut) orelse is_on(copy) orelse is_on(imgcopy)
  val () = if own then plat_own(p, false) else ()
  val () = if own then plat_own(p, true) else ()
  val () = if is_on(paste) then let
      val () = s.paste := On
    in
      plat_paste(p, false)
    end else ()
  val () = if is_on(imgrev) then s.side := SideFiles else ()
in
end

fun down_menu_close(s: &App_record >> _, ts2: !Tabs): void = let
  val () = s.active := 0
  val () = if is_on(s.split) andalso ilt(tabs_len(ts2), 2) then s.split := Off else ()
  val () = s.righti := 0
in
  save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
end

fun handle_down_context_menu(
  s: &App_record >> _, p: !Plat, ts0: Tabs, idx: int,
  skip: Toggle, inside: Toggle, item: int, ti: int, close: Toggle,
  imgdel: &Toggle >> _, clear: &Toggle >> _
): Tabs = let
  val cut = text_item_hit(s, skip, inside, item, TextCut)
  val copy = text_item_hit(s, skip, inside, item, TextCopy)
  val paste = text_item_hit(s, skip, inside, item, TextPaste)
  val () = clear := toggle_of(text_item_hit(s, skip, inside, item, TextClear))
  val imgcopy = image_item_hit(s, skip, inside, item, ImageCopy)
  val imgrev = image_item_hit(s, skip, inside, item, ImageReveal)
  val () = imgdel := toggle_of(image_item_hit(s, skip, inside, item, ImageDelete))
  val () = down_menu_clip(s, p, ts0, idx, toggle_of(cut), toggle_of(copy), toggle_of(imgcopy), toggle_of(paste), toggle_of(imgrev))
  val ts1 = cmd_if(ts0, idx, CMD_CUT, toggle_of(cut))
  val ts2 = tab_keep_one(drop_if(ts1, ti, close), close)
  val () = if is_on(close) then down_menu_close(s, ts2) else ()
in
  ts2
end

fun down_select_tree_row(s: &App_record >> _, row: int, valid_row: Toggle): void = let
  val () = s.sel := (if is_on(valid_row) then row else ~1)
  val () = s.drag := (if is_on(valid_row) then DragFile else DragNone)
  val () = s.dragi := (if is_on(valid_row) then row else ~1)
in
end

fun down_activate_first_tab(s: &App_record >> _): void = let
  val () = s.active := 0
in
  save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
end

fun handle_down_sidebar_click(
  s: &App_record >> _, f: !Font, ts: Tabs, onside: Toggle, x: int, y: int
): Tabs = let
  val row = idiv(isub(y, 72), UI_TREE_ROW_HEIGHT)
  val valid_row = ige(y, 72) andalso ige(row, 0) andalso ilt(row, s.tn)
  val openf = is_on(onside) andalso is_side_files(s.side) andalso valid_row andalso is_dir_mark(meta_dir(s.tmeta, row), DirNo)
  val () = if is_on(onside) andalso is_side_files(s.side) then down_select_tree_row(s, row, toggle_of(valid_row)) else ()
  val srow = if ige(y, 100) then idiv(isub(y, 100), UI_SEARCH_ROW_HEIGHT) else ~1
  val open_hit_flag = is_on(onside) andalso is_side_search(s.side) andalso ige(srow, 0) andalso ilt(srow, s.hn)
  val ts_hit = open_hit(ts, s.hmeta, s.hits, srow, toggle_of(open_hit_flag))
  val ts_row = open_row(ts_hit, s.tree, s.tmeta, row, toggle_of(openf))
  val () = if openf orelse open_hit_flag then down_activate_first_tab(s) else ()
  val () = if is_on(onside) andalso is_side_search(s.side) andalso not(open_hit_flag) then s.qfocus := On else ()
  val () = if is_on(onside) andalso is_side_config(s.side) then handle_sidebar_config_action(s, f, x, y) else ()
in
  ts_row
end

fun handle_down_context_menu_open(
  s: &App_record >> _, button: Btn, skip: Toggle, onside: Toggle, x: int, y: int
): void =
  if is_btn(button, BtnRight) andalso is_off(skip) then let
    val () = s.menux := x
    val () = s.menuy := y
  in
    if is_on(onside) then let
      val () = s.menu := MenuFileTree
      val row = idiv(isub(y, 72), UI_TREE_ROW_HEIGHT)
      val valid_row = ige(y, 72) andalso ige(row, 0) andalso ilt(row, s.tn)
    in
      s.sel := (if valid_row then row else ~1)
    end else s.menu := (if is_kind(s.hitk, KImage) then MenuImage else MenuText)
  end else ()

fun on_down_tabs(s: &App_record >> _, p: !Plat, f: !Font, r: !Rend, ev: &event, w: int, x: int, y: int, sidew: int, skip: Toggle, onbar: Toggle, onside: Toggle, button: Btn, inside: Toggle, item: int): void = let
  val ts0 = s.tabs
  val () = s.tabs := TNil()
  val idx = pane_of(s.focus, s.active, s.righti)
  var ti: int = ~1
  var close: bool = false
  val () = handle_down_tab_bar_selection(s, ts0, f, r, onbar, skip, x, topbar_tab_start_x(), topbar_mode_btn_x(w), ti, close)
  var imgdel: Toggle = Off
  var clear: Toggle = Off
  val ts1 = handle_down_context_menu(s, p, ts0, idx, skip, inside, item, ti, toggle_of(close), imgdel, clear)
  val ts2 = handle_down_sidebar_click(s, f, ts1, onside, x, y)
  val ts3 = handle_editor_click(s, f, r, ts2, ev, x, y, w, sidew, skip, onbar, onside, button, idx, imgdel, clear)
  val () = handle_down_context_menu_open(s, button, skip, onside, x, y)
  val ph = s.tabs
  val () = s.tabs := ts3
  val () = tabs_free(ph)
  val () = if is_on(skip) then s.menu := MenuNone else ()
in
end

fun on_down_panes(s: &App_record >> _, p: !Plat, f: !Font, r: !Rend, ev: &event, w: int): void = let
  val x = ev_x(ev)
  val y = ev_y(ev)
  val () = s.downx := x
  val () = s.downy := y
  val sidew = if not(is_side_none(s.side)) then UI_SIDEBAR_WIDTH else 0
  val button = button_of(ev_button(ev))
  val skip = not(is_menu_none(s.menu))
  val onbar = ilt(y, UI_TOPBAR_HEIGHT)
  val onside = not(skip) andalso igt(sidew, 0) andalso ilt(x, sidew) andalso not(onbar)
  val item = idiv(isub(y, s.menuy), UI_MENU_ITEM_HEIGHT)
  val inside = ige(x, s.menux) andalso ilt(x, iadd(s.menux, UI_MENU_WIDTH)) andalso ige(y, s.menuy)
  val () = if skip then handle_context_menu_action(s, toggle_of(inside), item) else ()
  val () = font_set_px(f, s.fontpx)
  val () = if onbar andalso not(skip) then handle_topbar_action(s, w, x) else ()
  val () = on_down_tabs(s, p, f, r, ev, w, x, y, sidew, toggle_of(skip), toggle_of(onbar), toggle_of(onside), button, toggle_of(inside), item)
in
end

fun on_down(a: !App, p: !Plat, f: !Font, r: !Rend, ev: &event, w: int, h: int): void =
  case+ a of
  | @APP(s) =>
      if is_on(s.vault_select) then let
        val () = handle_vault_select_click(s, ev_x(ev), ev_y(ev), w, h)
      in
        fold@(a)
      end else let
        val () = on_down_panes(s, p, f, r, ev, w)
      in
        fold@(a)
      end

fun on_motion(a: !App, ev: &event): void =
  case+ a of
  | @APP(s) => let
      val x = ev_x(ev)
      val y = ev_y(ev)
      val () = s.hoverx := x
      val () = s.hovery := y
      val () = if ige(s.downx, 0) andalso ige(s.dragi, 0) andalso ilt(s.downy, UI_TOPBAR_HEIGHT) then
        if igt(iabs(isub(x, s.downx)), 8) then s.drag := DragTab else ()
      else ()
    in
      fold@(a)
    end

fun on_up_split_tab(s: &App_record >> _, w: int, x: int): void = let
  val sidew = if not(is_side_none(s.side)) then UI_SIDEBAR_WIDTH else 0
  val mid = iadd(sidew, idiv(isub(w, sidew), 2))
in
  if ige(x, mid) then (
    s.split := On;
    s.righti := s.dragi;
    s.focus := On;
    save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
  ) else ()
end

fun on_up_reorder_tab(s: &App_record >> _, f: !Font, r: !Rend, x: int): void = let
  val tab_x0 = topbar_tab_start_x()
  var target_ti: int = ~1
  var dummy_close: bool = false
  val () = tab_hit_test(f, r, s.tabs, tab_x0, x, target_ti, dummy_close)
  val ntabs = tabs_len(s.tabs)
  val ti = if ige(target_ti, 0) then target_ti else if ige(x, tab_x0) then isub(ntabs, 1) else 0
in
  if ige(ti, 0) andalso ilt(ti, ntabs) andalso ine(ti, s.dragi) then let
    val+ ~PAIR(one, rest) = tabs_detach(s.tabs, s.dragi)
    val () = s.tabs := tabs_insert(rest, ti, one)
    val () = s.active := ti
    val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
  in
  end else ()
end

fun report_move_failure(rn: int, src: !Buf): void =
  if ieq(rn, 0) then () else report_failure("tree_move", cstr(src))

fun move_dragged_file(s: &App_record >> _, row: int): void = let
  var srcp = buf_make(8)
  var dstp = buf_make(8)
  var name = buf_make(8)
  var final = buf_make(8)
  val () = row_path(s.tree, s.tmeta, s.dragi, srcp)
  val () = row_path(s.tree, s.tmeta, row, dstp)
  val () = base_name(srcp, name)
  val () = child_path(dstp, name, final)
  val rn = fs_rename(cstr(srcp), cstr(final))
  val () = report_move_failure(rn, srcp)
  val () = s.treedirty := On
  val () = buf_free(srcp)
  val () = buf_free(dstp)
  val () = buf_free(name)
in
  buf_free(final)
end

fun on_up_move_file(s: &App_record >> _, y: int): void = let
  val row = idiv(isub(y, 72), UI_TREE_ROW_HEIGHT)
in
  if ige(row, 0) andalso ilt(row, s.tn) andalso ine(row, s.dragi) andalso is_dir_mark(meta_dir(s.tmeta, row), DirYes) then move_dragged_file(s, row)
  else ()
end

fun on_up_drop(s: &App_record >> _, f: !Font, r: !Rend, w: int, x: int, y: int): void =
  if is_drag_tab(s.drag) andalso igt(y, UI_TOPBAR_HEIGHT) then on_up_split_tab(s, w, x)
  else if is_drag_tab(s.drag) andalso ilt(y, UI_TOPBAR_HEIGHT) andalso ige(s.dragi, 0) then on_up_reorder_tab(s, f, r, x)
  else if is_drag_file(s.drag) andalso ige(s.sel, 0) then on_up_move_file(s, y)
  else ()

fun on_up_clamp_active(s: &App_record >> _): void = let
  val n = tabs_len(s.tabs)
  val () = if ige(s.active, n) then s.active := imax(0, isub(n, 1)) else ()
  val () = if ilt(s.active, 0) then s.active := 0 else ()
in
end

fun on_up(a: !App, f: !Font, r: !Rend, ev: &event, w: int): void =
  case+ a of
  | @APP(s) => let
      val x = ev_x(ev)
      val y = ev_y(ev)
      val () = on_up_drop(s, f, r, w, x, y)
      val () = s.drag := DragNone
      val () = s.dragi := ~1
      val () = s.downx := ~1
      val () = s.downy := ~1
      val () = on_up_clamp_active(s)
    in
      fold@(a)
    end

fun on_wheel(a: !App, ev: &event, w: int, h: int): void =
  case+ a of
  | @APP(s) => let
      val dv = if is_btn(button_of(ev_button(ev)), BtnWheelUp) then ~48 else 48
      val idx = pane_of(s.focus, s.active, s.righti)
      val ts = s.tabs
      val () = s.tabs := TNil()
      val ph = s.tabs
      val () = s.tabs := tabs_scroll(ts, idx, dv, 100000)
      val () = tabs_free(ph)
      val () = seen_int(w)
      val () = seen_int(h)
    in
      fold@(a)
    end

fun on_sel_paste(s: &App_record >> _, p: !Plat, ev: &event): void = let
  val cap = buf_cap(s.scratch)
  val n = plat_read_buf(p, ev, s.scratch, cap)
  val idx = pane_of(s.focus, s.active, s.righti)
  val ts = s.tabs
  val () = s.tabs := TNil()
  val ph = s.tabs
  val ts2 = tabs_ins_buf(ts, idx, s.scratch, n)
  val () = tabs_sync_vfs(ts2, idx)
  val () = s.tabs := ts2
  val () = tabs_free(ph)
  val () = s.paste := Off
in
end

fun on_sel(a: !App, p: !Plat, ev: &event): void =
  case+ a of
  | @APP(s) => let
      val k = event_of(ev_kind(ev))
      val nclip = buf_len(s.clip)
      val () = if is_ev(k, EvSelReq) then plat_reply_buf(p, ev, s.clip, nclip)
        else if is_ev(k, EvSelNotify) andalso is_on(s.paste) then on_sel_paste(s, p, ev)
        else ()
    in
      fold@(a)
    end

implement app_event(a, p, f, r, ev, w, h) = let
  val k = event_of(ev_kind(ev))
in
  if is_ev(k, EvKey) then on_key(a, p, f, ev)
  else if is_ev(k, EvDown) then on_down(a, p, f, r, ev, w, h)
  else if is_ev(k, EvUp) then on_up(a, f, r, ev, w)
  else if is_ev(k, EvMotion) then on_motion(a, ev)
  else if is_ev(k, EvWheel) then on_wheel(a, ev, w, h)
  else if is_ev(k, EvSelReq) orelse is_ev(k, EvSelNotify) then on_sel(a, p, ev)
  else ()
end
extern fun find_img_exh(doc: !Doc, i: int): int = "mac#anth_die_int"

fun find_img_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), doc: !Doc, i: int): int =
  if recfuel > 0 then (
    if ige(i, doc_nnodes(doc)) then ~1
    else if is_kind(doc_node_kind(doc, i), KImage) then i
    else find_img_m(recfuel - 1, doc, iadd(i, 1))
  ) else find_img_exh(doc, i)

fun find_img(doc: !Doc, i: int): int = find_img_m(airlock_nat(MAX_REC_FUEL), doc, i)

fun selftest_write_notes(): int = let
  var f1 = buf_make(40)
  var f2 = buf_make(40)
  var body = buf_make(32)
  val () = bstr(f1, "/tmp/anth-s/a.md")
  val () = bstr(f2, "/tmp/anth-s/b.md")
  val () = bstr(body, "anthracite bir\n")
  val w1 = write_text(f1, body)
  val () = bclear(body)
  val () = bstr(body, "anthracite iki\n")
  val w2 = write_text(f2, body)
  val () = buf_free(f1)
  val () = buf_free(f2)
  val () = buf_free(body)
in
  (if ieq(w1, 1) andalso ieq(w2, 1) then 1 else 0)
end

fun selftest_search(d1: !Buf): int = let
  var q = buf_make(16)
  val () = bstr(q, "anthracite")
  val writes_ok = selftest_write_notes()
  var hits = buf_make(64)
  var hmeta = buf_make(64)
  var hn: int = 0
  val () = refresh_search(d1, q, hits, hmeta, hn)
  val search_ok = if ige(hn, 2) andalso ieq(writes_ok, 1) then 1 else 0
  val () = buf_free(q)
  val () = buf_free(hits)
  val () = buf_free(hmeta)
in
  search_ok
end

fun selftest_flow(r: !Rend): @(int, int, Doc, Cache, Buf, Buf) = let
  val doc = doc_open()
  val () = doc_insert(doc, c_str_ptr("hello\n\n![](/tmp/anth-t.png)\n\nworld\n"), c_strlen("hello\n\n![](/tmp/anth-t.png)\n\nworld\n"))
  var cache = CNil()
  var vault = buf_make(8)
  val () = bstr(vault, "/tmp")
  var scratch = buf_make(256)
  val height = prep_doc(doc, cache, r, vault, 18, 720)
  val ii = find_img(doc, 0)
  val iy = if ige(ii, 0) then doc_node_y(doc, ii) else ~1
  val ih = if ige(ii, 0) then doc_node_height(doc, ii) else 0
  val flow_ok = if ige(ii, 0) andalso igt(ih, 8) andalso ige(height, iadd(iy, ih)) then 1 else 0
in
  @(flow_ok, ih, doc, cache, vault, scratch)
end

fun selftest_tabs(d1: !Buf): int = let
  val docA = doc_open()
  val () = doc_insert(docA, c_str_ptr("[[b]]\n"), 6)
  val () = doc_set_caret_move(docA, 2)
  var ta = buf_make(4)
  var pa = buf_make(4)
  val tsA = tabs_add(TNil(), docA, pa, ta)
  val docB = doc_open()
  var tb = buf_make(4)
  var pb = buf_make(4)
  val tsB = tabs_add(tsA, docB, pb, tb)
  val n2 = tabs_len(tsB)
  val tsC = tabs_drop(tsB, 1)
  val n1 = tabs_len(tsC)
  val tsD = wiki_open(tsC, 0, d1, 0)
  val nw = tabs_len(tsD)
  val () = tabs_free(tsD)
in
  (if ieq(n2, 2) andalso ieq(n1, 1) andalso ieq(nw, 2) then 1 else 0)
end

fun selftest_move_ops(sub: !Buf, src: !Buf, dstp: !Buf): int = let
  val mv = fs_rename(cstr(src), cstr(dstp))
  val moved = fs_exists(cstr(dstp))
  val () = seen_int(fs_unlink(cstr(dstp)))
  val gone = fs_exists(cstr(dstp))
  val () = seen_int(fs_rmdir(cstr(sub)))
in
  (if ieq(mv, 0) andalso ieq(moved, 1) andalso ieq(gone, 0) then 1 else 0)
end

fun selftest_files(): int = let
  var sub = buf_make(40)
  val () = bstr(sub, "/tmp/anth-s/sub")
  val () = seen_int(fs_mkdir(cstr(sub)))
  var src = buf_make(48)
  val () = bstr(src, "/tmp/anth-s/move.md")
  var one = buf_make(4)
  val () = bstr(one, "x\n")
  val () = seen_int(write_text(src, one))
  var dstp = buf_make(48)
  val () = bstr(dstp, "/tmp/anth-s/sub/move.md")
  val files_ok = selftest_move_ops(sub, src, dstp)
  val () = buf_free(sub)
  val () = buf_free(src)
  val () = buf_free(one)
  val () = buf_free(dstp)
in
  files_ok
end

fun selftest_draw_doc(fnt: !Font, r: !Rend, doc: !Doc, vault: !Buf, cache: &Cache >> _, scratch: &Buf >> _): void = let
  var py: int = 0
  var pa: int = 0
  val () = draw_nodes(fnt, r, doc, 0, 0, 800, 600, 0, 18, vault, cache, scratch, 0, py, pa, ViewEdit)
  val () = draw_nodes(fnt, r, doc, 0, 0, 800, 600, 0, 18, vault, cache, scratch, 0, py, pa, ViewRead)
  val () = draw_doc(fnt, r, doc, 0, 0, 800, 600, 0, 18, vault, cache, scratch, ViewRead)
in
end

fun selftest_widgets_a(fnt: !Font, r: !Rend, scratch: !Buf): void = let
  val () = ui_draw_border(r, 10, 10, 100, 50, 1, col_line())
  val () = ui_draw_shadow(r, 10, 10, 100, 50, 4)
  val () = ui_draw_icon(fnt, r, UI_ICON_FOLDER, 12, 12, 12, col_accent())
  val () = ui_divider(r, 0, 0, 100, Horizontal)
  val () = ui_badge(fnt, r, 20, 50, "badge", col_bar(), col_accent())
  val () = ui_button(fnt, r, 20, 70, 80, 24, "button", Off, Off)
  val () = ui_hover_label(fnt, r, 20, 100, 80, 20, "hover", Off)
  val () = ui_expander(fnt, r, 20, 125, On, Off)
  val () = ui_scroll_bar(r, 20, 210, 8, 100, Vertical, 500, 100, 50, Off, Off)
  val () = ui_line_edit_draw(fnt, r, 20, 320, 120, 24, scratch, 0, 0, On, "test")
in
end

fun selftest_widgets_b(fnt: !Font, r: !Rend): void = let
  val () = ui_pane_begin(r, 150, 10, 200, 150, col_bg())
  val () = ui_pane_draw_header(fnt, r, 150, 10, 200, "Pane Header", On)
  val () = ui_menu_bar_button(fnt, r, 150, 200, 60, 24, "Menu", On, Off)
  val () = ui_icon_button(fnt, r, UI_ICON_SETTINGS, "Options", 150, 230, 80, 24, Off, Off)
  val () = ui_cell(fnt, r, 150, 260, 160, 20, 0, On, On, UI_ICON_FOLDER, "Doc", "5 kb", On, Off)
  val () = ui_loading_overlay(fnt, r, 800, 600, 50, "Loading", "Please wait...")
  val () = ui_code_slice(fnt, r, 150, 290, 200, 20, 42, "val x = 1", On, On, Off)
  val () = ui_error_label(fnt, r, 150, 315, "Error")
  val () = ui_help_label(fnt, r, 150, 335, "Help")
in
end

fun selftest_draw(r: !Rend, doc: Doc, cache0: Cache, vault: Buf, scratch0: Buf): void = let
  val fnt = font_open()
  val () = rend_begin(r, 800, 600)
  var cache = cache0
  var scratch = scratch0
  val () = selftest_draw_doc(fnt, r, doc, vault, cache, scratch)
  val () = selftest_widgets_a(fnt, r, scratch)
  val () = selftest_widgets_b(fnt, r)
  val () = font_free(fnt)
  val () = doc_free(doc)
  val () = cache_free(cache)
  val () = buf_free(vault)
  val () = buf_free(scratch)
in
end

fun selftest_report(search_ok: Toggle, flow_ok: Toggle, ih: int, chrome_ok: Toggle, files_ok: Toggle): int = let
  val () = print("ui search=")
  val () = print_int(toggle_int(search_ok))
  val () = print(" flow=")
  val () = print_int(toggle_int(flow_ok))
  val () = print(" h=")
  val () = print_int(ih)
  val () = print(" chrome=")
  val () = print_int(toggle_int(chrome_ok))
  val () = print(" files=")
  val () = print_int(toggle_int(files_ok))
  val () = print_newline()
in
  (if is_on(search_ok) andalso is_on(flow_ok) andalso is_on(chrome_ok) andalso is_on(files_ok) then 1 else 0)
end

implement app_selftest(r) = let
  var d1 = buf_make(32)
  val () = bstr(d1, "/tmp/anth-s")
  val () = seen_int(fs_mkdir(cstr(d1)))
  val search_ok = selftest_search(d1)
  val @(flow_ok, ih, doc, cache, vault, scratch) = selftest_flow(r)
  val chrome_ok = selftest_tabs(d1)
  val files_ok = selftest_files()
  val () = selftest_draw(r, doc, cache, vault, scratch)
  val () = buf_free(d1)
in
  selftest_report(toggle_of(ieq(search_ok, 1)), toggle_of(ieq(flow_ok, 1)), ih, toggle_of(ieq(chrome_ok, 1)), toggle_of(ieq(files_ok, 1)))
end
