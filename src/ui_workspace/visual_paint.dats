#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "mem.sats"
staload "data_ast/doc.sats"
staload "data_ast/doc_visual.sats"
staload "data_ast/visual_rows.sats"
staload "data_font/font.sats"
staload "data_font/font_text.sats"
staload "data_font/font_text_paint.sats"
staload "data_font/font_paint.sats"
staload "data_font/private/font_text_dispatch.sats"
staload "data_font/private/font_storage.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "ui_workspace/visual_paint.sats"
fun row_x(f: !Font,row: VisualRow,width: int,colx: int,scratch: !Buf): int =
  if font_text_result_pixels(font_text_direction_code(f,scratch,isub(row.finish,row.start))) = 1 then
    iadd(colx,imax(0,isub(width,row.width))) else colx
fun fixed_row(f: !Font,r: !Rend,d: !Doc,rows: !VisualRows,i: int,range: TextRange,paint: TextPaint,
  colx: int,oy: int,scroll: int,lh: int,c: uint,scratch: &Buf >> _): int = let
  val row=visual_rows_at(rows,i) val+ VisualRows(text,map,lines,data,count,key)=rows
  val ()=buf_set_len(scratch,0) val ()=buf_append_at(scratch,text,row.start,isub(row.finish,row.start))
  val a=imax(range.start,row.start) val b=imin(range.finish,row.finish)
  val selected: TextRange= @{start=isub(a,row.start),finish=isub(b,row.start)}
  val operation=case+ paint of | PaintGlyphs(request) => PaintGlyphs(selected) | PaintSelection(request,h) => PaintSelection(selected,h)
  val x=row_x(f,row,key.width,colx,scratch)
  val y=isub(iadd(oy,iadd(doc_line_y(d,row.line),imul(row.ordinal,key.height))),scroll)
in if ilt(a,b) then font_text_result_pixels(font_text_paint(f,r,scratch,isub(row.finish,row.start),operation,x,y,c)) else 0 end
fun row_paint(f: !Font,r: !Rend,d: !Doc,rows: !VisualRows,i: int,range: TextRange,paint: TextPaint,
  colx: int,oy: int,scroll: int,lh: int,c: uint,scratch: &Buf >> _): int = let
  val+ VisualRows(t,m,l,data,n,key)=rows val old=f_get_px(f) val ()=f_set_px_val(f,key.px)
  val result=fixed_row(f,r,d,rows,i,range,paint,colx,oy,scroll,lh,c,scratch)
  val ()=f_set_px_val(f,old)
in result end
extern fun exhausted(): int = "mac#anth_die_int"
fun walk{n:nat} .<n>. (fuel: int(n),f: !Font,r: !Rend,d: !Doc,rows: !VisualRows,i: int,range: TextRange,paint: TextPaint,
  colx: int,oy: int,scroll: int,lh: int,ph: int,c: uint,scratch: &Buf >> _): int =
  if fuel = 0 then exhausted() else let val+ VisualRows(t,m,l,data,count,key)=rows
  in if ige(i,count) then 0 else let val row=visual_rows_at(rows,i)
    val y=isub(iadd(oy,iadd(doc_line_y(d,row.line),imul(row.ordinal,key.height))),scroll)
  in if ige(row.start,range.finish) then 0 else let
    val width=if ile(doc_line_step(d,row.line),0) orelse ilt(iadd(y,key.height),oy) orelse igt(y,iadd(oy,ph)) then 0
      else row_paint(f,r,d,rows,i,range,paint,colx,oy,scroll,lh,c,scratch)
    val rest=walk(fuel-1,f,r,d,rows,iadd(i,1),range,paint,colx,oy,scroll,lh,ph,c,scratch)
  in imax(width,rest) end end end
fun paint(f: !Font,r: !Rend,d: !Doc,rows: !VisualRows,a: int,b: int,operation: TextPaint,
  colx: int,oy: int,scroll: int,lh: int,ph: int,c: uint,scratch: &Buf >> _): int = let
  val range: TextRange= @{start=visual_rows_offset(rows,a),finish=visual_rows_offset(rows,b)}
  val i=visual_rows_find(rows,range.start)
in walk(airlock_nat(MAX_REC_FUEL),f,r,d,rows,i,range,operation,colx,oy,scroll,lh,ph,c,scratch) end
implement visual_draw_slice(f,r,d,a,b,colx,oy,scroll,lh,ph,c,scratch) = let val state=doc_visual_take(d)
  val width=case+ state of | None_vt() => 0 | Some_vt(rows) =>
    paint(f,r,d,rows,a,b,PaintGlyphs(@{start=a,finish=b}),colx,oy,scroll,lh,ph,c,scratch)
  val ()=doc_visual_put(d,state)
in width end
implement visual_draw_selection(f,r,d,colx,oy,scroll,lh,scratch) = let val state=doc_visual_take(d)
  val a=imin(doc_caret(d),doc_anchor(d)) val b=imax(doc_caret(d),doc_anchor(d))
  val ()=case+ state of | None_vt() => () | Some_vt(rows) => let val+ VisualRows(t,m,l,data,n,key)=rows
    in seen_int(paint(f,r,d,rows,a,b,PaintSelection(@{start=a,finish=b},key.height),colx,oy,scroll,key.height,65536,col_sel(),scratch)) end
  val ()=doc_visual_put(d,state)
in () end
implement visual_draw_band(f,r,d,a,b,colx,oy,scroll,lh,ph,offset,height,c,scratch) = let val state=doc_visual_take(d)
  val ()=case+ state of | None_vt() => () | Some_vt(rows) =>
    seen_int(paint(f,r,d,rows,a,b,PaintSelection(@{start=a,finish=b},height),colx,iadd(oy,offset),scroll,lh,ph,c,scratch))
  val ()=doc_visual_put(d,state)
in () end
