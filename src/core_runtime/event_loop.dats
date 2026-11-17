#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "airlock.sats"
staload "mem.sats"
staload "flag.sats"
staload "core_platform/platform.sats"
staload "core_platform/x11.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"
staload "ui_workspace/application/ui.sats"
staload "core_runtime/event_loop.sats"
staload "core_runtime/text_engine_startup.sats"
staload "core_runtime/event_repaint.sats"
staload "core_runtime/frame_trace.sats"
staload "core_runtime/performance.sats"
staload "os/fs.sats"

fun damage(a: !App, k: Ev, ev: &event): Repaint =
  if is_ev(k, EvMotion) then
    if app_motion_changes(a, ev) then RepaintNeeded() else RepaintClean()
  else event_repaint(k)

fun dispatch(p: !Plat,a: !App,f: !Font,r: !Rend,ev: &event): Repaint = let
  var w: int = 0
  var h: int = 0
  val ()=platform_dimensions(p,w,h)
  val k=event_of(ev_kind(ev))
  val changed=damage(a,k,ev)
  val ()=if is_ev(k,EvKey) then plat_ensure_im(p) else ()
  val ()=if is_ev(k,EvClose) then plat_stop(p) else ()
  val ()=if is_ev(k,EvResize) then plat_set_wh(p,ev_w(ev),ev_h(ev)) else ()
  val ()=app_event(a,p,f,r,ev,w,h)
in changed end

fun drain_batch {batch:nat} .<batch>. (
  batch_left: int(batch), p: !Plat, a: !App, f: !Font, r: !Rend, dirty: Repaint
): Repaint =
  if batch_left = 0 then dirty
  else let
    val pending = plat_pending(p)
  in
    if not(event_batch_has_budget(batch_left, pending)) then dirty
    else let
      var ev: event
      val () = plat_next(p, ev)
      val changed = dispatch(p, a, f, r, ev)
    in
      if is_off(plat_running(p)) then dirty
      else drain_batch(batch_left - 1, p, a, f, r, repaint_merge(dirty, changed))
    end
  end

fun drain(p: !Plat, a: !App, f: !Font, r: !Rend): Repaint = let
  val t0 = performance_now_ns()
  val dirty = drain_batch(airlock_nat(EVENT_DRAIN_BATCH_LIMIT), p, a, f, r, RepaintClean())
  val () = performance_phase_end(PERF_PHASE_EVENT_DISPATCH, t0)
in
  dirty
end

extern fun frame_fuel_exhausted(p: !Plat, a: !App, f: !Font, r: !Rend, loaded: bool): void = "mac#anth_die_void"

fun frame_present(p: !Plat, a: !App, f: !Font, r: !Rend): void = let
  val started=mono_ns()
  val pf0 = performance_now_ns()
  var w: int = 0
  var h: int = 0
  val () = platform_dimensions(p, w, h)
  val () = rend_begin(r, w, h)
  val () = app_draw(a, f, r, w, h)
  val () = rend_flush(r)
  val ps0 = performance_now_ns()
  val ()=plat_swap(p)
  val () = performance_phase_end(PERF_PHASE_PLAT_SWAP, ps0)
  val () = performance_phase_end(PERF_PHASE_FRAME_TOTAL, pf0)
in
  frame_trace(started)
end

fun frame_draw_if_needed(p: !Plat,a: !App,f: !Font,r: !Rend,dirty: Repaint): void =
  if app_work_pending(a) then frame_present(p,a,f,r)
  else case+ dirty of | RepaintClean() => () | RepaintNeeded() => frame_present(p,a,f,r)
fun frame_draw(p: !Plat, a: !App, f: !Font, r: !Rend, loaded: bool,dirty: Repaint): bool = let
  val loaded2 = if not(loaded) then workspace_font_start(f) else loaded
  val () = frame_draw_if_needed(p,a,f,r,dirty)
  val () = seen_int(plat_wait(p, if app_work_pending(a) then 0 else app_idle_wait(a)))
in
  loaded2
end

fun frame_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), p: !Plat, a: !App, f: !Font, r: !Rend, loaded: bool): void =
  if recursion_fuel_available(recfuel) then (
    if is_off(plat_running(p)) then ()
    else let
      val dirty = drain(p, a, f, r)
    in
      if is_off(plat_running(p)) then ()
      else frame_with_fuel(recfuel - 1, p, a, f, r, frame_draw(p, a, f, r, loaded,dirty))
    end
  ) else frame_fuel_exhausted(p, a, f, r, loaded)

fun first_frame(p: !Plat,a: !App,f: !Font,r: !Rend): void = let
  val ()=frame_present(p,a,f,r)
  val ()=println!("event=workspace_frame status=presented")
in seen_int(plat_wait(p,if app_work_pending(a) then 0 else app_idle_wait(a))) end

implement event_loop_run(p, a, f, r, loaded) = let val initial=drain(p,a,f,r)
in if is_off(plat_running(p)) then () else let
  val ready=if loaded then loaded else workspace_font_start(f)
  val ()=first_frame(p,a,f,r)
in frame_with_fuel(airlock_nat(MAX_REC_FUEL),p,a,f,r,ready) end end
