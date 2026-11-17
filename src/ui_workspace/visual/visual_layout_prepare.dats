#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "data_ast/document/doc.sats"
staload "data_ast/layout/doc_visual.sats"
staload "data_ast/layout/visual_rows.sats"
staload "data_ast/layout/doc_geometry.sats"
staload "data_ast/layout/layout_internal.sats"
staload "data_font/resources/font.sats"
staload "core_render/render.sats"
staload "data_font/text/font_text.sats"
staload "data_font/atlas/font_glyph_id.sats"
staload "data_font/native/ownership/private/font_native_owner.sats"
staload "data_font/resources/private/font_storage.sats"
staload "data_font/resources/font_document_metrics.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/visual/visual_layout.sats"
staload "core_runtime/performance.sats"
implement visual_layout_key(f,d,width,mode) = let
  val p=font_native_current(f,GlyphPrimaryFace()) val a=font_native_current(f,GlyphFallbackFace())
  val metrics=font_document_metrics(f)
  val range=doc_view_range(d)
  val is_read = if is_view_read(mode) then 1 else 0
  val @(r0, r1) = doc_raw_lines(d, is_read)
in @{version=doc_layout_version(d),width=imax(1,width),px=font_get_px(f),height=font_document_line_height(f,font_line_h(f)),ascent=metrics.ascent,primary=p.font,fallback=a.font,
  primaryGeneration=p.generation,fallbackGeneration=a.generation,
  projection=if is_view_read(mode) then VisualRendered() else VisualSource(),sourceStart=range.start,sourceFinish=range.finish,
  rawStart=r0,rawFinish=r1} end
staload "airlock.sats"
staload "mem.sats"
staload "os/fs.sats"
(* Viewport overscan above and below, in viewport heights / 2. *)
macdef BAND_OVERSCAN_HALVES = 1
macdef BAND_SETTLE_FUEL = 4
macdef LINE_SEARCH_FUEL = 40
fun fresh(f: !Font,r: !Rend,d: !Doc,width: int,mode: ViewMode,exact: bool): void = let
  var rows=visual_projection_make(d,visual_layout_key(f,d,width,mode))
  val ()=visual_wrap_build(f,r,d,rows,exact)
  val+ ~VisualRows(t,m,l,data,n,old,plans)=rows
  val ()=doc_visual_put(d,Some_vt(VisualRows(t,m,l,data,n,visual_layout_key(f,d,width,mode),plans)))
in doc_layout_cache_store(d,~1,0,0,~1,doc_get_wrap(d)) end
fun stored_matches(f: !Font,d: !Doc,width: int,mode: ViewMode): bool = let
  val state=doc_visual_take(d)
  val hit=case+ state of | None_vt() => false | Some_vt(rows) => visual_rows_matches(rows,visual_layout_key(f,d,width,mode))
  val ()=doc_visual_put(d,state)
in hit end
fun stored_pending{b:bool}(state: !option_vt(VisualRows,b)): int = case+ state of
  | None_vt() => 0 | Some_vt(rows) => visual_rows_pending(rows)
implement visual_layout_pending(d) = let
  val state=doc_visual_take(d) val count=stored_pending(state) val ()=doc_visual_put(d,state)
in count end
(* Faces load lazily while shaping, so the font part of the key can change from
   "not loaded" during this call; rows shaped here used the loaded faces. *)
fun rekey(rows: VisualRows,key: VisualKey): VisualRows = let val+ ~VisualRows(t,m,l,data,n,old,plans)=rows
in VisualRows(t,m,l,data,n,key,plans) end
fun wrap_stored(f: !Font,r: !Rend,d: !Doc,width: int,mode: ViewMode,range: VisualLineRange,deadline: lint): int = let
  val state=doc_visual_take(d)
in case+ state of
  | ~None_vt() => let val ()=doc_visual_put(d,None_vt()) in 0 end
  | ~Some_vt(rows0) => let var rows=rows0
      val wrapped=visual_wrap_lines(f,r,d,rows,range,deadline)
      val ()=doc_visual_put(d,Some_vt(rekey(rows,visual_layout_key(f,d,width,mode))))
      val ()=if igt(wrapped.count,0) then doc_layout_mark_rows(d,wrapped.first,wrapped.last) else ()
    in wrapped.count end end
implement visual_layout_wrap_range(f,r,d,width,mode,range,deadline) =
  if not(font_text_active(f)) orelse not(stored_matches(f,d,width,mode)) then 0 else let
    val t0 = performance_now_ns()
    val wrapped=wrap_stored(f,r,d,width,mode,range,deadline)
  in performance_phase_end(PERF_PHASE_VISUAL_PREPARE, t0); wrapped end
implement visual_layout_prepare(f,r,d,width,mode) =
  if not(font_text_active(f)) then () else let
    val t0 = performance_now_ns()
    val () = if stored_matches(f,d,width,mode) then seen_int(wrap_stored(f,r,d,width,mode,@{first=0,last=doc_nlines(d)},0L))
      else fresh(f,r,d,width,mode,true)
  in performance_phase_end(PERF_PHASE_VISUAL_PREPARE, t0) end
implement visual_layout_prepare_deferred(f,r,d,width,mode) =
  if not(font_text_active(f)) orelse stored_matches(f,d,width,mode) then () else let
    val t0 = performance_now_ns()
    val () = fresh(f,r,d,width,mode,false)
  in performance_phase_end(PERF_PHASE_VISUAL_PREPARE, t0) end

extern fun line_search_exhausted(): int = "mac#anth_die_int"
fun line_search{n:nat} .<n>. (fuel: int(n),d: !Doc,y: int,lo: int,hi: int): int =
  if fuel = 0 then line_search_exhausted() else if ige(lo,hi) then imax(0,isub(lo,1)) else let
    val mid=iadd(lo,idiv(isub(hi,lo),2))
  in if ile(doc_line_y(d,mid),y) then line_search(fuel-1,d,y,iadd(mid,1),hi) else line_search(fuel-1,d,y,lo,mid) end
fun line_at(d: !Doc,y: int): int = line_search(airlock_nat(LINE_SEARCH_FUEL),d,y,0,doc_nlines(d))
fun view_top(d: !Doc,view: VisualViewport): int =
  iadd(if ilt(view.anchorLine,0) then 0 else doc_line_y(d,view.anchorLine),view.offset)
fun view_band(d: !Doc,view: VisualViewport): VisualLineRange = let
  val top=view_top(d,view) val margin=imul(idiv(view.height,2),BAND_OVERSCAN_HALVES)
in @{first=line_at(d,imax(0,isub(top,margin))),last=line_at(d,iadd(iadd(top,view.height),margin))} end
fun layout_height(d: !Doc,mode: ViewMode,lh: int,width: int): int =
  doc_layout_mode(d,lh,if is_view_read(mode) then 1 else 0,width)
(* Shaping a line changes heights below it, which can move other lines into the
   band, so re-lay out until the band has no placeholders (bounded). *)
fun settle{n:nat} .<n>. (fuel: int(n),f: !Font,r: !Rend,d: !Doc,width: int,mode: ViewMode,lh: int,view: VisualViewport): int = let
  val height=layout_height(d,mode,lh,width)
  val wrapped=visual_layout_wrap_range(f,r,d,width,mode,view_band(d,view),0L)
in if ieq(wrapped,0) then height else if fuel = 0 then layout_height(d,mode,lh,width)
  else settle(fuel-1,f,r,d,width,mode,lh,view) end
implement visual_layout_prepare_band(f,r,d,width,mode,lh,view) = let
  val ()=visual_layout_prepare_deferred(f,r,d,width,mode)
in settle(airlock_nat(BAND_SETTLE_FUEL),f,r,d,width,mode,lh,view) end
implement visual_layout_background(f,r,d,width,mode,view,budget_ns) =
  if ile(visual_layout_pending(d),0) orelse not(stored_matches(f,d,width,mode)) then () else let
    val deadline=mono_ns()+budget_ns
    val band=view_band(d,view)
    val below=visual_layout_wrap_range(f,r,d,width,mode,@{first=iadd(band.last,1),last=doc_nlines(d)},deadline)
    val above=if mono_ns() < deadline then visual_layout_wrap_range(f,r,d,width,mode,@{first=0,last=isub(band.first,1)},deadline) else 0
  in seen_int(iadd(below,above)) end
