#include "data_font/font_span_internal.hats"
implement font_span_tab_place(layout,index,pen) = let val part=font_span_part(layout,index)
in if ile(part.width,0) then Some_vt(SpanShaping()) else if igt(part.width,idiv(2147483647,4)) then Some_vt(SpanOverflow())
  else let val stop=imul(part.width,4) val remainder=pen % g0int2int_int_llint(stop)
    val width=isub(stop,airlock_i32(remainder))
    val placed: FontSpanPart= @{kind=SpanTabPart(),start=part.start,finish=part.finish,sourceStart=part.sourceStart,
      sourceEnd=part.sourceEnd,level=part.level,width=width,x=0}
    val ()=font_span_set_part(layout,index,placed)
  in None_vt() end end
