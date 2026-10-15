#include "font_native_test.hats"
staload "data_ast/doc.sats"
staload "data_ast/doc_visual.sats"
staload "data_ast/layout_internal.sats"
staload "data_ast/visual_rows.sats"
staload "data_font/font_document_metrics.sats"
staload "data_font/private/font_storage.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/visual_layout.sats"
staload "ui_workspace/visual_paint.sats"
staload "ui_workspace/visual_query.sats"
staload "ui_workspace/visual_navigation.sats"
staload "ui_workspace/ui_tab.sats"
staload "ui_workspace/ui_cmd.sats"
staload "ui_workspace/ui_render.sats"
staload "font_gl_airlock.sats"
extern fun native_visual_layout_cases(f: !Font,r: !Rend): int = "ext#native_visual_layout_cases"
fun bytes(s: string): Buf = let val n=c_strlen(s) val b=buf_make(n)
  fun copy{k:nat} .<k>. (left: int(k),s: string,b: !Buf,i: int): void =
    if left = 0 then () else let val ()=buf_set(b,i,c_str_byte(s,i)) in copy(left-1,s,b,iadd(i,1)) end
  val ()=copy(airlock_nat(n),s,b,0) val ()=buf_set_len(b,n)
in b end
fun rows{n:nat} .<n>. (left: int(n),snapshot: !VisualRows,i: int): int =
  if left = 0 then 0 else let val row=visual_rows_at(snapshot,i)
    val+ VisualRows(text,map,lines,data,count,key)=snapshot
    val starts=ilt(row.start,row.finish) orelse ieq(row.width,0)
    val bounded=ile(row.width,key.width)
  in iadd(if starts andalso bounded then 0 else 1,rows(left-1,snapshot,iadd(i,1))) end
fun snapshot(d: !Doc): int = let val state=doc_visual_take(d)
  val errors=case+ state of | None_vt() => 1 | Some_vt(s) => let val+ VisualRows(t,m,l,data,n,k)=s
  in rows(airlock_nat(n),s,0) end
  val ()=doc_visual_put(d,state)
in errors end
fun pixel{n:nat} .<n>. (left: int(n),image: !Buf,i: int,height: int,found: &int >> _): int =
  if left = 0 then 0 else let val at=imul(i,4)
    val blue=ieq(buf_get(image,at),58) andalso ieq(buf_get(image,iadd(at,1)),74) andalso ieq(buf_get(image,iadd(at,2)),92)
    val x=imod(i,128) val y=isub(127,idiv(i,128))
    val ()=if blue then found := iadd(found,1) else ()
    val error=if blue andalso (ige(x,90) orelse ige(y,height)) then 1 else 0
  in iadd(error,pixel(left-1,image,iadd(i,1),height,found)) end
fun selection(f: !Font,r: !Rend,d: !Doc,lh: int,endpos: int): int = let
  val ()=doc_set_caret_move(d,0) val ()=doc_set_caret_extend(d,endpos)
  val ()=rend_begin(r,640,480) var scratch=buf_make(256)
  val ()=visual_draw_selection(f,r,d,20,20,0,lh,scratch) val ()=rend_flush(r)
  val image=buf_make(65536) val ()=font_gl_read_pixels(image,128,128) var found: int=0
  val errors=pixel(airlock_nat(16384),image,0,doc_line_step(d,0),found)
  val ()=buf_free(image) val ()=buf_free(scratch)
in iadd(errors,if igt(found,0) then 0 else 1) end
fun caret(f: !Font,d: !Doc,lh: int): int = let var scratch=buf_make(256)
  val ()=doc_set_caret_move(d,0)
  val click=visual_click_source(f,d,20,20,20,20,0,lh,scratch)
  val point=visual_caret_point(f,d,20,20,0,lh,scratch)
  val ()=buf_free(scratch)
in if ieq(click,0) andalso ieq(point.x,20) andalso ieq(point.y,20) then 0 else 1 end
fun font_scope(f: !Font,r: !Rend,d: !Doc,lh: int,endpos: int): int = let var scratch=buf_make(256)
  val old=f_get_px(f) val ()=doc_set_caret_move(d,2)
  val expected=visual_caret_point(f,d,20,20,0,lh,scratch)
  val ()=font_set_px(f,48) val actual=visual_caret_point(f,d,20,20,0,font_line_h(f),scratch)
  val restored=ieq(f_get_px(f),48) andalso ieq(expected.x,actual.x) andalso ieq(expected.y,actual.y)
  val pixels=selection(f,r,d,font_line_h(f),endpos)
  val ()=font_set_px(f,old) val ()=buf_free(scratch)
in iadd(pixels,if restored then 0 else 1) end
fun equal{n:nat} .<n>. (left: int(n),b: !Buf,s: string,i: int): bool =
  if left = 0 then true else ieq(buf_get(b,i),c_str_byte(s,i)) andalso equal(left-1,b,s,iadd(i,1))
fun projected{b:bool}(state: !option_vt(VisualRows,b)): int = case+ state of
  | None_vt() => 1 | Some_vt(rows) => let val+ VisualRows(text,map,lines,data,n,key)=rows
    val expected="İŞ Başlık\n" val length=c_strlen(expected)
  in if ieq(buf_len(text),length) andalso equal(airlock_nat(length),text,expected,0) then 0 else 1 end
fun markdown(f: !Font,r: !Rend): int = let val d=doc_open() val b=bytes("**İŞ** [[note|Başlık]]\n")
  val ()=doc_insert_buf(d,b,buf_len(b)) val ()=buf_free(b)
  val ()=visual_layout_prepare(f,r,d,90,ViewRead) val state=doc_visual_take(d)
  val errors=projected(state) val ()=doc_visual_put(d,state) val ()=doc_free(d)
in errors end
fun hard_lines(f: !Font,r: !Rend): int = let val d=doc_open() val b=bytes("A\342\200\251B\013C\r\nD")
  val ()=doc_insert_buf(d,b,buf_len(b)) val ()=buf_free(b)
  val ()=visual_layout_prepare(f,r,d,600,ViewEdit)
  val lh=font_document_line_height(f,font_line_h(f)) val h=doc_layout_mode(d,lh,0,680)
  val expected=ieq(doc_visual_line_rows(d,0),3) andalso ieq(doc_line_step(d,0),imul(3,lh))
  val ()=doc_free(d)
in if expected then 0 else 1 end
fun navigation(f: !Font,r: !Rend): int = let val d=doc_open() val b=bytes("İŞİİ İŞİİ İŞİİ İŞİİ\n")
  val ()=doc_insert_buf(d,b,buf_len(b)) val ()=buf_free(b) val ()=doc_set_caret_move(d,0)
  val ()=visual_layout_prepare(f,r,d,90,ViewEdit) var scratch=buf_make(256)
  val height=doc_layout_mode(d,font_document_line_height(f,font_line_h(f)),0,170)
  val ts=TCons(d,buf_make(1),buf_make(1),0,TNil())
  val (down,left)=tabs_visual_vertical(f,r,ts,0,CMD_SELECT_DOWN(),scratch)
  val moved=igt(tabs_caret(down,0),0) andalso is_cmd(left,CMD_NONE())
  val (up,left2)=tabs_visual_vertical(f,r,down,0,CMD_CARET_UP(),scratch)
  val returned=ieq(tabs_caret(up,0),0) andalso is_cmd(left2,CMD_NONE())
  val ()=tabs_free(up) val ()=buf_free(scratch)
in if moved andalso returned then 0 else 1 end
fun test(f: !Font,r: !Rend,d: !Doc): int = let
  val b=bytes("İŞİİ İŞİİ İŞİİ İŞİİ\n\nبِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\n")
  val ()=doc_insert_buf(d,b,buf_len(b)) val ()=buf_free(b)
  val lh=font_document_line_height(f,font_line_h(f))
  val ()=visual_layout_prepare(f,r,d,90,ViewEdit) val h=doc_layout_mode(d,lh,0,170)
  val count=doc_visual_line_rows(d,0)
  val geometry=igt(count,1) andalso ieq(doc_line_step(d,0),imul(count,lh))
    andalso ige(doc_line_y(d,2),doc_line_step(d,0)) andalso igt(h,doc_line_y(d,2))
  val errors=iadd(snapshot(d),iadd(font_scope(f,r,d,lh,isub(doc_line_start(d,1),1)),caret(f,d,lh)))
  val ()=visual_layout_prepare(f,r,d,260,ViewEdit) val resized=doc_layout_mode(d,lh,0,340)
  val fewer=ilt(doc_visual_line_rows(d,0),count)
in iadd(errors,if geometry andalso fewer then 0 else 1) end
fun folding_and_task(f: !Font, r: !Rend): int = let
  val d = doc_open()
  val b = bytes("# Baslik 1\nParagraf 1\n\nParagraf 2\n# Baslik 2\n- [ ] Gorev 1\n")
  val () = doc_insert_buf(d, b, buf_len(b))
  val () = buf_free(b)
  val lh = font_document_line_height(f, font_line_h(f))
  val () = visual_layout_prepare(f, r, d, 200, ViewEdit)
  val h_orig = doc_layout_mode(d, lh, 0, 280)
  val n0 = node_covering(d, 5, 0, 0, 0, ~1)
  val ok_h0 = is_heading(doc_node_kind(d, n0))
  val () = doc_toggle(d, n0)
  val () = visual_layout_prepare(f, r, d, 200, ViewEdit)
  val h_folded = doc_layout_mode(d, lh, 0, 280)
  val ok_fold = ilt(h_folded, h_orig) andalso ieq(doc_line_step(d, 1), 0) andalso ieq(doc_line_step(d, 2), 0) andalso ieq(doc_line_step(d, 3), 0)
  val () = doc_toggle(d, n0)
  val () = visual_layout_prepare(f, r, d, 200, ViewEdit)
  val h_restored = doc_layout_mode(d, lh, 0, 280)
  val ok_unfold = ieq(h_restored, h_orig) andalso igt(doc_line_step(d, 1), 0)
  val task_y = iadd(doc_line_y(d, 5), idiv(lh, 2))
  val n_task = node_covering(d, task_y, 0, 0, 0, ~1)
  val ok_task_node = is_kind(doc_node_kind(d, n_task), KTask)
  val () = doc_toggle_task(d, n_task)
  val tst = doc_node_start(d, n_task)
  val mark_pos = iadd(tst, 3)
  val ok_task_toggle = ieq(doc_byte(d, mark_pos), 120)
  val () = doc_free(d)
  val ok = ok_h0 andalso ok_fold andalso ok_unfold andalso ok_task_node andalso ok_task_toggle
in
  if ok then 0 else 1
end
implement native_visual_layout_cases(f,r) = let val before=mem_live() val d=doc_open()
  val errors=iadd(test(f,r,d),iadd(iadd(markdown(f,r),hard_lines(f,r)),iadd(navigation(f,r),folding_and_task(f,r)))) val ()=doc_free(d) val delta=isub(mem_live(),before)
  val ()=println!("event=native_visual_layout errors=",errors," retained_font_source_bytes=",delta)
in errors end
