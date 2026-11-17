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
fun layout_raw_matches(layout: !Buf, raw0: int, raw1: int): bool
fun layout_raw_store(layout: &Buf >> _, raw0: int, raw1: int): void
(* Dirty line range: ~1/~2 when empty; layout_cache_store clears it. *)
fun layout_dirty_first(layout: !Buf): int
fun layout_dirty_last(layout: !Buf): int
fun layout_mark_dirty(layout: &Buf >> _, first: int, last: int): void
