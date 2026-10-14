#include "data_font/font_span_internal.hats"
staload "data_text/bidi_line.sats"
staload "data_font/private/font_span_order.sats"
fun append(layout: !FontSpanLayout,seen: !Buf,index: int,state: FontSpanOrderState): FontSpanOrderState =
  if ine(buf_get(seen,index),0) then state else let
    val row=font_span_part(layout,index) val+ FontSpanLayout(a,items,runs,parts,order,n,width,direction)=layout
    val ()=buf_set(seen,index,1) and ()=buf_set32(order,state.count,index)
    val placed: FontSpanPart= @{kind=row.kind,start=row.start,finish=row.finish,sourceStart=row.sourceStart,sourceEnd=row.sourceEnd,
      level=row.level,width=row.width,x=state.x}
    val ()=font_span_set_part(layout,index,placed)
  in @{count=iadd(state.count,1),x=iadd(state.x,row.width)} end
fun visual{n:nat} .<n>. (left: int(n),layout: !FontSpanLayout,order: !BidiOrder,map: !Buf,seen: !Buf,
  index: int,state: FontSpanOrderState): FontSpanOrderState = if left = 0 then state else let
    val scalar=bidi_order_index(order,index) val row=buf_get32(map,scalar)
    val next=append(layout,seen,row,state)
  in visual(left-1,layout,order,map,seen,iadd(index,1),next) end
fun tail{n:nat} .<n>. (left: int(n),layout: !FontSpanLayout,seen: !Buf,index: int,
  state: FontSpanOrderState): FontSpanOrderState = if left = 0 then state else
  tail(left-1,layout,seen,iadd(index,1),append(layout,seen,index,state))
implement font_span_order_walk(layout,order,map,seen) =
  visual(airlock_nat(bidi_order_count(order)),layout,order,map,seen,0,@{count=0,x=0})
implement font_span_order_tail(layout,seen,state) = let val+ FontSpanLayout(a,items,runs,rows,order,n,width,direction)=layout
in tail(n,layout,seen,0,state) end
