#include "data_font/text/span/font_span_internal.hats"
staload "data_font/resources/font_paint.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
fun paint_slot{b:bool}(slot: !option_vt(FontNativeRun,b),f: !Font,r: !Rend,paint: TextPaint,x: double,y: double,c: uint): FontRunStatus =
  case+ slot of | None_vt() => FontRunGraph() | Some_vt(run) => let val+ FontNativeRun(p,token)=run
  in if paint.selection then let val ()=font_position_select(r,p,paint.range,x,y,paint.height,c)
    in FontRunReady() end else font_position_paint(f,r,p,token,paint.range,x,y,c) end
fun slot(runs: !FontSpanRuns,i: int,f: !Font,r: !Rend,paint: TextPaint,x: double,y: double,c: uint): FontRunStatus = let
  val+ @FontSpanRuns(pf,gc | p,n)=runs val (at,restore | cell)=array_ptr_takeout(pf | p,i2sz(airlock_below(i,n)))
  val result=paint_slot(!cell,f,r,paint,x,y,c) prval ()=pf := restore(at) prval ()=fold@(runs)
in result end
fun tab(r: !Rend,part: FontSpanPart,paint: TextPaint,x: double,y: double,c: uint): void =
    if paint.selection andalso igt(part.sourceEnd,paint.range.start) andalso ilt(part.sourceStart,paint.range.finish) then
      rend_quad_pixels(r,u_zero(),ShadeSolid(),x+n_i2d(part.x)/64.0,y,n_i2d(part.width)/64.0,n_i2d(paint.height),0.0,0.0,0.0,0.0,c) else ()
fun part(f: !Font,r: !Rend,runs: !FontSpanRuns,i: int,p: FontSpanPart,paint: TextPaint,x: double,y: double,c: uint): FontRunStatus =
  case+ p.kind of | SpanLineEndPart() => FontRunReady()
    | SpanSkipPart() => FontRunReady()
    | SpanTabPart() => let val ()=tab(r,p,paint,x,y,c) in FontRunReady() end
    | SpanTextPart() => slot(runs,i,f,r,paint,x+n_i2d(p.x)/64.0,y,c)
fun walk{n:nat} .<n>. (left: int(n),f: !Font,r: !Rend,layout: !FontSpanLayout,paint: TextPaint,x: double,y: double,c: uint,i: int): FontRunStatus =
  if left = 0 then FontRunReady() else let val+ FontSpanLayout(a,items,runs,rows,order,count,w,d)=layout
    val row=buf_get32(order,i) val status=part(f,r,runs,row,font_span_part(layout,row),paint,x,y,c)
  in case+ status of | FontRunReady() => walk(left-1,f,r,layout,paint,x,y,c,iadd(i,1))
    | FontRunFace() => status | FontRunScale() => status | FontRunOverflow() => status
    | FontRunRaster() => status | FontRunGraph() => status end
implement font_span_paint(f,r,layout,paint,x,y,c) = let val+ FontSpanLayout(a,items,runs,rows,order,n,w,d)=layout
  val status=font_span_check(f,layout)
in case+ status of | FontRunReady() => walk(n,f,r,layout,paint,x,y,c,0)
  | FontRunFace() => status | FontRunScale() => status | FontRunOverflow() => status
  | FontRunRaster() => status | FontRunGraph() => status end
