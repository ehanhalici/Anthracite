#include "data_font/text/span/font_span_internal.hats"
implement font_span_part(layout,index) = let val+ FontSpanLayout(a,items,runs,rows,order,n,width,direction)=layout
in arrayptr_get_at<FontSpanPart>(rows,i2sz(airlock_below(index,n))) end
implement font_span_set_part(layout,index,row) = let val+ FontSpanLayout(a,items,runs,rows,order,n,width,direction)=layout
in arrayptr_set_at<FontSpanPart>(rows,i2sz(airlock_below(index,n)),row) end
implement font_span_width(layout) = let val+ FontSpanLayout(a,items,runs,rows,order,n,width,direction)=layout in width end
implement font_span_direction(layout) = let val+ FontSpanLayout(a,items,runs,rows,order,n,width,direction)=layout in direction end
fun total{n:nat} .<n>. (left: int(n),layout: !FontSpanLayout,index: int,sum: llint): Option_vt(int) =
  if sum > 2147483647LL then None_vt() else if left = 0 then Some_vt(airlock_i32(sum)) else let
    val row=font_span_part(layout,index)
  in total(left-1,layout,iadd(index,1),sum+g0int2int_int_llint(row.width)) end
implement font_span_total(layout) = let val+ FontSpanLayout(a,items,runs,rows,order,n,width,direction)=layout
in total(n,layout,0,0LL) end
implement font_span_dispose(layout) = let val+ ~FontSpanLayout(a,items,runs,rows,order,n,width,direction)=layout
  val ()=native_text_analysis_dispose(a) and ()=native_text_items_dispose(items)
  val ()=font_span_runs_dispose(runs) and ()=arrayptr_free(rows)
in buf_free(order) end
