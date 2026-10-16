staload "mem.sats"
staload "data_text/bidi/bidi_types.sats"
datavtype BidiOrder = BidiOrder of (Buf, int)
fun bidi_line_reset(work: !BidiWork, start: int, finish: int, base: int): void
fun bidi_line_order(work: !BidiWork, start: int, finish: int): BidiOrder
fun bidi_order_count(order: !BidiOrder): int
fun bidi_order_index(order: !BidiOrder, i: int): int
fun bidi_order_dispose(order: BidiOrder): void
