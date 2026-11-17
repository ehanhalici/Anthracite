staload "data_ast/document/doc.sats"
fun doc_math_block_height(line_height: int): int

fun doc_layout_ast_prepare(d: !Doc, line_height: int): void
fun doc_layout_line_hidden(d: !Doc, start: int, stop: int, node_count: int): int
fun doc_layout_widget_height(d: !Doc, start: int, stop: int, node_count: int): int
fun doc_layout_heading_padding(d: !Doc, start: int, stop: int, node_count: int, line_height: int): int
fun doc_layout_store_line(d: !Doc, line: int, y: int, step: int): void
fun doc_layout_store_node_y(d: !Doc, node: int, y: int): void
fun doc_layout_version(d: !Doc): int
fun doc_layout_cache_match(d: !Doc, version: int, key: int, mode: int): bool
fun doc_layout_cache_height(d: !Doc): int
fun doc_layout_cache_store(d: !Doc, version: int, key: int, height: int, mode: int, wrap: int): void
fun doc_layout_cached_wrap(d: !Doc): int
(* Visual rows of lines [first,last] changed without a document edit: the next
   doc_layout_mode with a matching key re-lays out from there instead of fully. *)
fun doc_layout_mark_rows(d: !Doc, first: int, last: int): void
fun doc_layout_dirty_rows(d: !Doc): @(int, int)
