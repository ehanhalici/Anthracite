#include "data_font/text/span/font_span_internal.hats"
fun skip(kind: FontSpanPartKind): bool = case+ kind of
  | SpanTextPart() => false | SpanTabPart() => false
  | SpanLineEndPart() => false | SpanSkipPart() => true
fun check{n:nat} .<n>. (left: int(n),f: !Font,runs: !FontSpanRuns,layout: !FontSpanLayout,
  index: int): FontRunStatus =
  if left = 0 then FontRunReady() else let
    val row=font_span_part(layout,index)
  in case+ skip(row.kind) of
    | true => check(left-1,f,runs,layout,iadd(index,1))
    | false => case+ font_span_runs_check(runs,index,f) of
      | FontRunReady() => check(left-1,f,runs,layout,iadd(index,1))
      | FontRunFace() => FontRunFace() | FontRunScale() => FontRunScale()
      | FontRunOverflow() => FontRunOverflow() | FontRunRaster() => FontRunRaster()
      | FontRunGraph() => FontRunGraph() end
implement font_span_check(f,layout) = let
  val+ FontSpanLayout(a,items,runs,rows,order,n,width,direction)=layout
in check(n,f,runs,layout,0) end
