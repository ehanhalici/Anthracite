#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "mem.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/layout/doc_visual.sats"
staload "data_ast/layout/visual_rows.sats"
staload "data_font/resources/font.sats"
staload "data_font/text/font_text.sats"
staload "data_font/resources/font_hit.sats"
staload "data_font/resources/font_document_metrics.sats"
staload "data_font/resources/private/font_storage.sats"
staload "data_font/text/private/font_text_dispatch.sats"
staload "ui_workspace/visual/visual_query.sats"
extern fun exhausted(): int = "mac#anth_die_int"
fun source{n:nat} .<n>. (fuel: int(n),rows: !VisualRows,value: int,lo: int,hi: int): int =
  if fuel = 0 then exhausted() else if ige(lo,hi) then imax(0,isub(lo,1)) else let
    val mid=iadd(lo,idiv(isub(hi,lo),2)) val at=visual_rows_offset(rows,mid)
  in if ile(at,value) then source(fuel-1,rows,value,iadd(mid,1),hi) else source(fuel-1,rows,value,lo,mid) end
fun row_x(f: !Font,rows: !VisualRows,row: VisualRow,colx: int,scratch: &Buf >> _): int = let
  val+ VisualRows(text,map,lines,data,count,key)=rows
  val ()=buf_set_len(scratch,0) val ()=buf_append_at(scratch,text,row.start,isub(row.finish,row.start))
  val rtl=if ieq(row.start,row.finish) then 0 else font_text_result_pixels(font_text_direction_code(f,scratch,isub(row.finish,row.start)))
in if ieq(rtl,1) then iadd(colx,imax(0,isub(key.width,row.width))) else colx end
fun caret(f: !Font,d: !Doc,rows: !VisualRows,colx: int,oy: int,scroll: int,lh: int,scratch: &Buf >> _): VisualPoint = let
  val at=visual_rows_offset(rows,doc_caret(d)) val i=visual_rows_find(rows,at) val row=visual_rows_at(rows,i)
  val x=row_x(f,rows,row,colx,scratch)
  val offset=if ieq(row.start,row.finish) then 0 else font_text_result_pixels(font_text_hit(f,scratch,isub(row.finish,row.start),QueryCaret(isub(at,row.start))))
in @{x=iadd(x,offset),y=isub(iadd(oy,iadd(doc_line_y(d,row.line),imul(row.ordinal,lh))),scroll)} end
fun fixed_caret(f: !Font,d: !Doc,rows: !VisualRows,colx: int,oy: int,scroll: int,scratch: &Buf >> _): VisualPoint = let
  val+ VisualRows(t,m,l,data,n,key)=rows val old=font_get_px(f) val ()=font_set_px_val(f,key.px)
  val point=caret(f,d,rows,colx,oy,scroll,key.height,scratch) val ()=font_set_px_val(f,old)
in point end
implement visual_caret_point(f,d,colx,oy,scroll,lh0,scratch) = let val state=doc_visual_take(d)
  val result=case+ state of | None_vt() => @{x=colx,y=oy} | Some_vt(rows) => fixed_caret(f,d,rows,colx,oy,scroll,scratch)
  val ()=doc_visual_put(d,state)
in result end
fun line{n:nat} .<n>. (fuel: int(n),d: !Doc,y: int,lo: int,hi: int): int =
  if fuel = 0 then exhausted() else if ige(lo,hi) then imax(0,isub(lo,1)) else let val mid=iadd(lo,idiv(isub(hi,lo),2))
  in if ile(doc_line_y(d,mid),y) then line(fuel-1,d,y,iadd(mid,1),hi) else line(fuel-1,d,y,lo,mid) end
fun click(f: !Font,d: !Doc,rows: !VisualRows,x: int,y: int,colx: int,oy: int,scroll: int,lh: int,scratch: &Buf >> _): int = let
  val yy=iadd(isub(y,oy),scroll) val li=line(airlock_nat(32),d,yy,0,doc_nlines(d))
  val ordinal=imin(isub(visual_rows_count(rows,li),1),idiv(imax(0,isub(yy,doc_line_y(d,li))),imax(1,lh)))
  val+ VisualRows(t,m,l,data,count,key)=rows val row=visual_rows_at(rows,iadd(buf_get32(l,li),ordinal))
  val base=row_x(f,rows,row,colx,scratch) val target=imul(imin(33554431,imax(0,isub(x,base))),64)
  val offset=if ieq(row.start,row.finish) then 0 else font_text_result_pixels(font_text_hit(f,scratch,isub(row.finish,row.start),QueryClick(target)))
in source(airlock_nat(32),rows,iadd(row.start,offset),0,iadd(doc_len(d),1)) end
fun fixed_click(f: !Font,d: !Doc,rows: !VisualRows,x: int,y: int,colx: int,oy: int,scroll: int,scratch: &Buf >> _): int = let
  val+ VisualRows(t,m,l,data,n,key)=rows val old=font_get_px(f) val ()=font_set_px_val(f,key.px)
  val result=click(f,d,rows,x,y,colx,oy,scroll,key.height,scratch) val ()=font_set_px_val(f,old)
in result end
implement visual_click_source(f,d,x,y,colx,oy,scroll,lh0,scratch) = let val state=doc_visual_take(d)
  val result=case+ state of | None_vt() => 0 | Some_vt(rows) => fixed_click(f,d,rows,x,y,colx,oy,scroll,scratch)
  val ()=doc_visual_put(d,state)
in result end
