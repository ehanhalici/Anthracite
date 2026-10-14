staload "data_ast/doc.sats"
staload "data_ast/visual_rows.sats"
fun doc_visual_take(d: !Doc): Option_vt(VisualRows)
fun doc_visual_put(d: !Doc,rows: Option_vt(VisualRows)): void
fun doc_visual_line_rows(d: !Doc,line: int): int
fun doc_visual_active(d: !Doc): bool
fun doc_visual_index(d: !Doc): void
fun doc_visual_node_bottom(d: !Doc,index: int): Option(int)
