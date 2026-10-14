staload "mem.sats"
staload "data_font/font_span_types.sats"
staload "data_text/bidi_line.sats"
typedef FontSpanOrderState = @{count=int,x=int}
fun font_span_order_map(layout: !FontSpanLayout,map: !Buf,seen: !Buf): void
fun font_span_order_walk(layout: !FontSpanLayout,visual: !BidiOrder,map: !Buf,seen: !Buf): FontSpanOrderState
fun font_span_order_tail(layout: !FontSpanLayout,seen: !Buf,state: FontSpanOrderState): FontSpanOrderState
