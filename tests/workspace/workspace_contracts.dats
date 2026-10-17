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

macdef TEST_BUFFER_BYTES = 1024
macdef SESSION_FONT_PIXELS = 18
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
  val ()=conf_save_session(vault,"fixture.ttf",SESSION_FONT_PIXELS,0,1,0,1,1,
    SESSION_SIDEBAR_PIXELS,panes,directories,tabs)
  val ()=tabs_free(tabs)
  val ()=buf_free(panes)
in buf_free(directories) end

fun load_session(vault: string): int = let
  var font: Buf=buf_make(TEST_BUFFER_BYTES)
  var panes: Buf=buf_make(TEST_BUFFER_BYTES)
  var directories: Buf=buf_make(TEST_BUFFER_BYTES)
  var pixels: int=0 and view: int=0 and split: int=0 and active: int=0
  var right: int=0 and sidebar: int=0 and width: int=0
  val tabs=conf_load_session(vault,font,pixels,view,split,active,right,sidebar,width,panes,directories,TNil())
  val scalar_fields=ieq(pixels,SESSION_FONT_PIXELS) andalso ieq(view,0) andalso ieq(split,1)
    andalso ieq(active,0) andalso ieq(right,1) andalso ieq(sidebar,1) andalso ieq(width,SESSION_SIDEBAR_PIXELS)
  val text_fields=ieq(c_strcmp(buffer_c_string(font),"fixture.ttf"),0)
    andalso ieq(c_strcmp(buffer_c_string(directories),"folder\n"),0)
  val ()=tabs_free(tabs)
  val ()=buf_free(font)
  val ()=buf_free(panes)
  val ()=buf_free(directories)
in check(scalar_fields andalso text_fields) end

fun configuration(root: string): int = let
  val ()=save_session(root)
  var active: Buf=buf_make(TEST_BUFFER_BYTES)
  val loaded=conf_get_active_vault(active)
  val selected=loaded andalso ieq(c_strcmp(buffer_c_string(active),root),0)
  val ()=buf_free(active)
in iadd(check(selected),load_session(root)) end

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

fun documents{remaining:nat} .<remaining>. (remaining: int(remaining),index: int): int =
  if remaining > 0 then iadd(compare_document(document_case(index)),documents(remaining-1,iadd(index,1))) else 0

fun run(mode: string,root: string): int =
  if ieq(c_strcmp(mode,"image"),0) then images(root)
  else if ieq(c_strcmp(mode,"config"),0) then configuration(root)
  else if ieq(c_strcmp(mode,"document"),0) then documents(DOCUMENT_CASES,0) else 1

implement main0() =
  if ine(c_argc(),3) then exit(2) else let
    val before=mem_live()
    val errors=run(c_argv(1),c_argv(2))
    val ownership=check(ieq(before,mem_live()))
    val total=iadd(errors,ownership)
    val ()=println!("event=workspace_contracts mode=",c_argv(1)," errors=",total)
  in if igt(total,0) then exit(1) else () end
