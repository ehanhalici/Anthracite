staload "mem.sats"
staload "data_ast/doc.sats"
staload "data_ast/visual_rows.sats"
staload "data_font/font.sats"
staload "core_render/render.sats"
staload "ui_workspace/ui_common.sats"
fun visual_layout_prepare(f: !Font,r: !Rend,d: !Doc,width: int,mode: ViewMode): void
fun visual_projection_make(d: !Doc,key: VisualKey): VisualRows
fun visual_wrap_fill(f: !Font,r: !Rend,d: !Doc,rows: &VisualRows >> VisualRows): void
