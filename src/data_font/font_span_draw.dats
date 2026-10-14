#include "data_font/font_span_internal.hats"
staload "os/fs.sats"
fun part_draw(f: !Font,r: !Rend,runs: !FontSpanRuns,row: int,part: FontSpanPart,
  x: double,y: double,color: uint): FontRunStatus = case+ part.kind of
  | SpanTabPart() => FontRunReady() | SpanLineEndPart() => FontRunReady() | SpanSkipPart() => FontRunReady() | SpanTextPart() => let
    val result=font_span_runs_draw(runs,row,f,r,x+n_i2d(part.x)/64.0,y,color)
  in result.status end
fun walk{n:nat} .<n>. (left: int(n),f: !Font,r: !Rend,layout: !FontSpanLayout,
  x: double,y: double,color: uint,index: int): FontRunStatus = if left = 0 then FontRunReady() else let
    val+ FontSpanLayout(a,items,runs,rows,order,count,width,direction)=layout val row=buf_get32(order,index)
    val part=font_span_part(layout,row)
  in case+ part_draw(f,r,runs,row,part,x,y,color) of
    | FontRunReady() => walk(left-1,f,r,layout,x,y,color,iadd(index,1))
    | FontRunFace() => FontRunFace() | FontRunScale() => FontRunScale() | FontRunOverflow() => FontRunOverflow()
    | FontRunRaster() => FontRunRaster() | FontRunGraph() => FontRunGraph() end
implement font_span_draw(f,r,layout,x,y,color) = let val+ FontSpanLayout(a,items,runs,rows,order,n,width,direction)=layout
in case+ font_span_check(f,layout) of
  | FontRunReady() => walk(n,f,r,layout,x,y,color,0)
  | FontRunFace() => FontRunFace() | FontRunScale() => FontRunScale()
  | FontRunOverflow() => FontRunOverflow() | FontRunRaster() => FontRunRaster() | FontRunGraph() => FontRunGraph() end
