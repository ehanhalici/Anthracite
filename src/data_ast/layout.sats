staload "mem.sats"

fun layout_open(): Buf
fun layout_dispose(layout: Buf): void
fun layout_line_need(index: int): int
fun layout_line_put(layout: &Buf >> _, index: int, y: int, step: int, line_count: int): void
fun layout_line_y(layout: !Buf, index: int, line_count: int): int
fun layout_line_step(layout: !Buf, index: int, line_count: int): int
fun layout_node_need(index: int, line_count: int): int
fun layout_node_put_height(layout: &Buf >> _, index: int, height: int, line_count: int): void
fun layout_node_height(layout: !Buf, index: int, line_count: int): int
fun layout_node_put_y(layout: &Buf >> _, index: int, y: int, line_count: int): void
fun layout_node_y(layout: !Buf, index: int, line_count: int): int
fun layout_cache_matches(layout: !Buf, version: int, key: int, mode: int): bool
fun layout_cache_height(layout: !Buf): int
fun layout_cache_store(layout: &Buf >> _, version: int, key: int, height: int, mode: int, wrap: int): void
fun layout_wrap(layout: !Buf): int
