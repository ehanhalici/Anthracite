staload "mem.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/layout/visual_rows.sats"
staload "data_font/resources/font.sats"
staload "core_render/render.sats"
staload "ui_workspace/common/ui_common.sats"
(* Inclusive source-line range. *)
typedef VisualLineRange = @{first=int,last=int}
(* Per-row font size and vertical metrics of one source line. *)
typedef VisualRowStyle = @{px=int,height=int,ascent=int,top=int}
(* Shaping inputs of one projected source line [a,b); shaped=false for lines
   that get one trivial row (empty or outside the view range). *)
typedef VisualLineInput = @{line=int,a=int,b=int,target=int,style=VisualRowStyle,shaped=bool}
(* Rows shaped away from the document (worker threads), indexed by source
   line: rows (VISUAL_ROW_WORDS each, absolute projected offsets), per line
   first row and row count (count ~1 = no result), paragraph analyses. *)
datavtype VisualShaped = VisualShaped of (Buf,Buf,VisualParagraphs,int)
(* Lines shaped by one visual_wrap_lines call; first > last when count = 0. *)
typedef VisualWrapped = @{count=int,first=int,last=int}
(* Viewport in document coordinates: top = line_y(anchorLine) + offset (anchorLine < 0: top = offset). *)
typedef VisualViewport = @{anchorLine=int,offset=int,height=int}
(* Every line exact (embedded documents, callers without a viewport). *)
fun visual_layout_prepare(f: !Font,r: !Rend,d: !Doc,width: int,mode: ViewMode): void
(* Visible-first: on a stale key, rebuild rows with placeholders only (no shaping). *)
fun visual_layout_prepare_deferred(f: !Font,r: !Rend,d: !Doc,width: int,mode: ViewMode): void
(* Shapes pending lines in range until deadline (0L = no limit, at least one line
   otherwise); marks the shaped lines dirty so the next layout is incremental. Returns lines shaped. *)
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
fun visual_wrap_lines(f: !Font,r: !Rend,d: !Doc,rows: &VisualRows >> VisualRows,range: VisualLineRange,deadline: lint): VisualWrapped
fun visual_wrap_line_input(d: !Doc,rows: !VisualRows,line: int,cur: &int >> _): VisualLineInput
(* Shapes one projected line held alone in `text` (offsets 0..length) without
   any document: appends its rows to `out` (offsets relative to the line,
   line field 0) and returns its paragraph analysis. Used by workers. *)
fun visual_wrap_segment(f: !Font,text: !Buf,length: int,target: int,style: VisualRowStyle,out: &Buf >> _): Option_vt(VisualParagraph)
fun visual_shaped_make(lines: int): VisualShaped
fun visual_shaped_dispose(shaped: VisualShaped): void
fun visual_shaped_count(shaped: !VisualShaped): int
(* Records rows (relative to `a`) and the paragraph of `line`. *)
fun visual_shaped_add(shaped: &VisualShaped >> _,line: int,a: int,rows: !Buf,first: int,count: int,paragraph: Option_vt(VisualParagraph)): void
(* Splice: pending lines that have shaped rows take them; the rest are copied. *)
fun visual_wrap_apply(d: !Doc,rows: &VisualRows >> VisualRows,shaped: &VisualShaped >> _): VisualWrapped
