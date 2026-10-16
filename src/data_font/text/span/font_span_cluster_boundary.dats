#include "data_font/text/span/font_span_internal.hats"
staload "data_font/text/span/private/font_span_partition.sats"
fun boundary{n:nat} .<n>. (left: int(n),a: !NativeTextAnalysis,index: int): int =
  if left = 0 then index else if native_text_analysis_grapheme(a,index) then index
  else boundary(left-1,a,iadd(index,1))
implement font_span_cluster_finish(a,start,limit) =
  boundary(airlock_span(iadd(start,1),limit),a,iadd(start,1))
