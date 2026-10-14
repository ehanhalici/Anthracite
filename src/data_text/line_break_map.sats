staload "data_text/line_types.sats"
fun line_breaks_make(count: int): LineBreakMap
fun line_breaks_put(map: !LineBreakMap,index: int,boundary: LineBreak): void
fun line_break_at(map: !LineBreakMap,index: int): LineBreak
fun line_break_count(map: !LineBreakMap): int
fun line_breaks_dispose(map: LineBreakMap): void
