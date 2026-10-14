#include "data_font/font_span_internal.hats"
fun check{n:nat} .<n>. (left: int(n),f: !Font,runs: !FontSpanRuns,index: int): FontRunStatus =
  if left = 0 then FontRunReady() else case+ font_span_runs_check(runs,index,f) of
  | FontRunReady() => check(left-1,f,runs,iadd(index,1))
  | FontRunFace() => FontRunFace() | FontRunScale() => FontRunScale()
  | FontRunOverflow() => FontRunOverflow() | FontRunRaster() => FontRunRaster() | FontRunGraph() => FontRunGraph()
implement font_span_check(f,layout) = let val+ FontSpanLayout(a,items,runs,rows,order,n,width,direction)=layout
in check(n,f,runs,0) end
