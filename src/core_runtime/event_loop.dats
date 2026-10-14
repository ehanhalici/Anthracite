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
staload "data_font/font.sats"
staload "ui_workspace/ui.sats"
staload "core_runtime/event_loop.sats"
staload "core_runtime/text_engine_startup.sats"
staload "core_runtime/event_repaint.sats"
staload "core_runtime/frame_trace.sats"
staload "os/fs.sats"

fun is0(n: int): bool = n = 0

fun damage(a: !App,k: Ev,ev: &event): Repaint =
  if is_ev(k,EvMotion) then
    if app_motion_changes(a,ev) then RepaintNeeded() else RepaintClean()
  else event_repaint(k)

fun plat_read_buf(p: !Plat, ev: &event, dst: !Buf, cap: int): int =
  plat_read(p, ev, buf_ptr(dst), cap)

fun dispatch(p: !Plat,a: !App,f: !Font,r: !Rend,ev: &event): Repaint = let
  var w: int = 0
  var h: int = 0
  val ()=plat_wh(p,w,h)
  val k=event_of(ev_kind(ev))
  val changed=damage(a,k,ev)
  val ()=if is_ev(k,EvKey) then plat_ensure_im(p) else ()
  val ()=if is_ev(k,EvClose) then plat_stop(p) else ()
  val ()=if is_ev(k,EvResize) then plat_set_wh(p,ev_w(ev),ev_h(ev)) else ()
  val ()=app_event(a,p,f,r,ev,w,h)
in changed end

fun drain_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), p: !Plat, a: !App, f: !Font, r: !Rend,dirty: Repaint): Repaint =
  if recfuel > 0 then (
    if plat_pending(p) = 0 then dirty
    else let
      var ev: event
      val () = plat_next(p, ev)
      val changed=dispatch(p,a,f,r,ev)
    in
      if is_off(plat_running(p)) then dirty else
        drain_m(recfuel - 1, p, a, f, r,repaint_merge(dirty,changed))
    end
  ) else dirty (* Intentional 64-event batch: continuous input cannot starve presentation. *)

fun drain(p: !Plat, a: !App, f: !Font, r: !Rend): Repaint =
  drain_m(airlock_nat(64), p, a, f, r,RepaintClean())

extern fun frame_exh(p: !Plat, a: !App, f: !Font, r: !Rend, loaded: bool): void = "mac#anth_die_void"

fun frame_present(p: !Plat, a: !App, f: !Font, r: !Rend): void = let
  val started=mono_ns()
  var w: int = 0
  var h: int = 0
  val () = plat_wh(p, w, h)
  val () = rend_begin(r, w, h)
  val () = app_draw(a, f, r, w, h)
  val () = rend_flush(r)
  val ()=plat_swap(p)
in
  frame_trace(started)
end

fun frame_draw(p: !Plat, a: !App, f: !Font, r: !Rend, loaded: bool,dirty: Repaint): bool = let
  val loaded2 = if not(loaded) then workspace_font_start(f) else loaded
  val () = case+ dirty of | RepaintClean() => () | RepaintNeeded() => frame_present(p,a,f,r)
  val () = seen_int(plat_wait(p, ~1))
in
  loaded2
end

fun frame_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), p: !Plat, a: !App, f: !Font, r: !Rend, loaded: bool): void =
  if recfuel > 0 then (
    if is_off(plat_running(p)) then ()
    else let
      val dirty = drain(p, a, f, r)
    in
      if is_off(plat_running(p)) then ()
      else frame_m(recfuel - 1, p, a, f, r, frame_draw(p, a, f, r, loaded,dirty))
    end
  ) else frame_exh(p, a, f, r, loaded)

fun first_frame(p: !Plat,a: !App,f: !Font,r: !Rend): void = let
  val ()=frame_present(p,a,f,r)
  val ()=println!("event=workspace_frame status=presented")
in seen_int(plat_wait(p,~1)) end

implement event_loop_run(p, a, f, r, loaded) = let val initial=drain(p,a,f,r)
in if is_off(plat_running(p)) then () else let
  val ready=if loaded then loaded else workspace_font_start(f)
  val ()=first_frame(p,a,f,r)
in frame_m(airlock_nat(MAX_REC_FUEL),p,a,f,r,ready) end end
