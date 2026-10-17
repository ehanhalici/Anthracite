staload "mem.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/layout/visual_rows.sats"
datavtype DocGeometry = DocGeometry of (Buf,Option_vt(VisualRows),Buf,int)
(* Transfer view state, never AST/source ownership. Layout owns Y/height;
   the node snapshot holds per-view aux fields. Text/AST/anchors stay canonical. *)
fun doc_geometry_take(d: !Doc): DocGeometry
fun doc_geometry_put(d: !Doc,geometry: DocGeometry): void
fun doc_geometry_dispose(geometry: DocGeometry): void
fun doc_geometry_key(geometry: !DocGeometry): Option_vt(VisualKey)
fun doc_geometry_bytes(geometry: !DocGeometry): llint
fun doc_set_view_range(d: !Doc,start: int,finish: int): void
fun doc_view_range(d: !Doc): @{start=int,finish=int}
fun doc_parse_generation(d: !Doc): int
