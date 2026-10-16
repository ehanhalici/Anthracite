#include "data_font/text/span/font_span_internal.hats"
implement font_span_line_end_place(layout,index) = let val part=font_span_part(layout,index)
  val placed: FontSpanPart= @{kind=SpanLineEndPart(),start=part.start,finish=part.finish,
    sourceStart=part.sourceStart,sourceEnd=part.sourceEnd,level=part.level,width=0,x=0}
in font_span_set_part(layout,index,placed) end
