#include "data_font/text/span/font_span_internal.hats"
staload "data_font/text/span/private/font_span_order.sats"
fun scalar_rows{n:nat} .<n>. (left: int(n),map: !Buf,index: int,row: int): void =
  if left = 0 then () else let val ()=buf_set32(map,index,row)
  in scalar_rows(left-1,map,iadd(index,1),row) end
fun rows{n:nat} .<n>. (left: int(n),layout: !FontSpanLayout,map: !Buf,seen: !Buf,index: int): void =
  if left = 0 then () else let val part=font_span_part(layout,index)
    val ()=scalar_rows(airlock_nat(isub(part.finish,part.start)),map,part.start,index)
    val ()=buf_set(seen,index,0)
  in rows(left-1,layout,map,seen,iadd(index,1)) end
implement font_span_order_map(layout,map,seen) = let val+ FontSpanLayout(a,items,runs,parts,order,n,width,direction)=layout
in rows(n,layout,map,seen,0) end
