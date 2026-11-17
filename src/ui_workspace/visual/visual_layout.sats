staload "mem.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/layout/visual_rows.sats"
staload "data_font/resources/font.sats"
staload "core_render/render.sats"
staload "ui_workspace/common/ui_common.sats"
(* Inclusive source-line range. *)
typedef VisualLineRange = @{first=int,last=int}
(* Viewport in document coordinates: top = line_y(anchorLine) + offset (anchorLine < 0: top = offset). *)
typedef VisualViewport = @{anchorLine=int,offset=int,height=int}
(* Every line exact (embedded documents, callers without a viewport). *)
fun visual_layout_prepare(f: !Font,r: !Rend,d: !Doc,width: int,mode: ViewMode): void
(* Visible-first: on a stale key, rebuild rows with placeholders only (no shaping). *)
fun visual_layout_prepare_deferred(f: !Font,r: !Rend,d: !Doc,width: int,mode: ViewMode): void
(* Shapes pending lines in range until deadline (0L = no limit, at least one line
   otherwise); invalidates the layout cache when anything changed. Returns lines shaped. *)
fun visual_layout_wrap_range(f: !Font,r: !Rend,d: !Doc,width: int,mode: ViewMode,range: VisualLineRange,deadline: lint): int
(* Deferred rows, then layout + shape the viewport band until it is exact. Returns layout height. *)
fun visual_layout_prepare_band(f: !Font,r: !Rend,d: !Doc,width: int,mode: ViewMode,lh: int,view: VisualViewport): int
(* Shapes pending lines below, then above the viewport band within budget_ns. *)
fun visual_layout_background(f: !Font,r: !Rend,d: !Doc,width: int,mode: ViewMode,view: VisualViewport,budget_ns: lint): void
fun visual_layout_pending(d: !Doc): int
fun visual_layout_key(f: !Font,d: !Doc,width: int,mode: ViewMode): VisualKey
fun visual_projection_make(d: !Doc,key: VisualKey): VisualRows
fun visual_wrap_fill(f: !Font,r: !Rend,d: !Doc,rows: &VisualRows >> VisualRows): void
(* exact=false: placeholder rows only (visual_layout_prepare_deferred). *)
fun visual_wrap_build(f: !Font,r: !Rend,d: !Doc,rows: &VisualRows >> VisualRows,exact: bool): void
fun visual_wrap_lines(f: !Font,r: !Rend,d: !Doc,rows: &VisualRows >> VisualRows,range: VisualLineRange,deadline: lint): int
