#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "flag.sats"
staload "core_platform/x11.sats"
staload "core_platform/platform.sats"

implement event_of(n) =
  if n = EV_CLOSE then EvClose
  else if n = EV_RESIZE then EvResize
  else if n = EV_KEY then EvKey
  else if n = EV_DOWN then EvDown
  else if n = EV_UP then EvUp
  else if n = EV_MOTION then EvMotion
  else if n = EV_WHEEL then EvWheel
  else if n = EV_SEL_REQ then EvSelReq
  else if n = EV_SEL_NOTIFY then EvSelNotify
  else EvNone

fun ev_code(k: Ev): int = case+ k of
  | EvNone() => 0
  | EvClose() => 1
  | EvResize() => 2
  | EvKey() => 4
  | EvDown() => 5
  | EvUp() => 6
  | EvMotion() => 7
  | EvWheel() => 8
  | EvSelReq() => 9
  | EvSelNotify() => 10

implement is_ev(a, b) = ev_code(a) = ev_code(b)

implement key_id(k) = case+ k of
  | KeyLeft() => KEY_LEFT
  | KeyRight() => KEY_RIGHT
  | KeyUp() => KEY_UP
  | KeyDown() => KEY_DOWN
  | KeyBackspace() => KEY_BACKSPACE
  | KeyDelete() => KEY_DELETE
  | KeyHome() => KEY_HOME
  | KeyEnd() => KEY_END
  | KeyReturn() => KEY_RETURN
  | KeyTab() => KEY_TAB
  | KeyEscape() => KEY_ESCAPE
  | KeyPageUp() => KEY_PAGE_UP
  | KeyPageDown() => KEY_PAGE_DOWN

datavtype Plat_ = PLAT of @{
  dpy= ptr
, win= ulint
, ctx= ptr
, vi= ptr
, list= ptr
, im= ptr
, ic= ptr
, w= int
, h= int
, fd= int
, running= Toggle
, wm= ulint
, clip= ulint
, prim= ulint
, utf8= ulint
, targets= ulint
, prop= ulint
, png= ulint
}
(* skill.md 1. kural istisnasi: ATS2 soyut tip gerceklemesi (sats'taki absviewtype). Kanit disi cast veya ham C yoktur. *)
assume Plat = Plat_

fun zuli(): ulint = x_ulint0()

fun plat_dead(): Plat = PLAT(@{
  dpy= the_null_ptr, win= zuli(), ctx= the_null_ptr, vi= the_null_ptr
, list= the_null_ptr, im= the_null_ptr, ic= the_null_ptr
, w= 0, h= 0, fd= ~1, running= Off
, wm= zuli(), clip= zuli(), prim= zuli(), utf8= zuli()
, targets= zuli(), prop= zuli(), png= zuli()
})

fun plat_close_dead(dpy: ptr): Plat = let
  val () = x_close(dpy)
in
  plat_dead()
end

fun plat_abort_ctx(dpy: ptr, win: ulint, ctx: ptr, vi: ptr, list: ptr): Plat = let
  val () = if ptr_isnot_null(ctx) then x_destroy_ctx(dpy, ctx) else ()
  val () = x_destroy(dpy, win)
  val () = if ptr_isnot_null(vi) then x_free(vi) else ()
  val () = if ptr_isnot_null(list) then x_free(list) else ()
  val () = x_close(dpy)
in
  plat_dead()
end

fun plat_finish(dpy: ptr, win: ulint, ctx: ptr, vi: ptr, list: ptr, wm: ulint): Plat = let
  var im: ptr = the_null_ptr
  var ic: ptr = the_null_ptr
  val clip = x_intern(dpy, "CLIPBOARD", 0)
  val prim = x_intern(dpy, "PRIMARY", 0)
  val utf8 = x_intern(dpy, "UTF8_STRING", 0)
  val targets = x_intern(dpy, "TARGETS", 0)
  val prop = x_intern(dpy, "ANTHRACITE_SEL", 0)
  val png = x_intern(dpy, "image/png", 0)
  val () = x_flush(dpy)
in
  PLAT(@{
    dpy= dpy, win= win, ctx= ctx, vi= vi, list= list, im= im, ic= ic
  , w= 1100, h= 720, fd= x_fd(dpy), running= On
  , wm= wm, clip= clip, prim= prim, utf8= utf8
  , targets= targets, prop= prop, png= png
  })
end

fun plat_open_window(dpy: ptr, root: ulint, fb: ptr, visual: ptr, vi: ptr, list: ptr, depth: int): Plat = let
  val cmap = x_create_colormap(dpy, root, visual, x_alloc_none())
  val win = x_create_window(dpy, root, visual, depth, 80, 60, 1100, 720, cmap)
  val () = x_store_name(dpy, win, "Anthracite")
  val wm = x_intern(dpy, "WM_DELETE_WINDOW", 0)
  val () = x_wm(dpy, win, wm)
  val () = x_map(dpy, win)
  val () = x_sync(dpy, 0)
  val ctx = x_create_ctx(dpy, fb)
  val made = x_make_current(dpy, win, ctx)
in
  if made = 0 orelse ptr_is_null(ctx) then plat_abort_ctx(dpy, win, ctx, vi, list)
  else plat_finish(dpy, win, ctx, vi, list, wm)
end

fun plat_open_display(dpy: ptr): Plat = let
  val screen = x_default_screen(dpy)
  val root = x_root(dpy, screen)
  var fb: ptr = the_null_ptr
  var visual: ptr = the_null_ptr
  var vi: ptr = the_null_ptr
  var list: ptr = the_null_ptr
  var depth: int = 0
  val chose = x_choose_fb(dpy, screen, fb, visual, vi, list, depth)
in
  if chose = 0 then plat_close_dead(dpy)
  else plat_open_window(dpy, root, fb, visual, vi, list, depth)
end

implement plat_open() = let
  val () = x_install_signals()
  val () = x_err_install()
  val dpy = x_open(the_null_ptr)
in
  if ptr_is_null(dpy) then plat_dead() else plat_open_display(dpy)
end

implement plat_close(p) = let
  val+~PLAT(r) = p
in
  if ptr_is_null(r.dpy) then () else let
    val () = x_make_current_drop(r.dpy, zuli(), the_null_ptr)
    val () = x_close_im(r.im, r.ic)
    val () = x_destroy_ctx(r.dpy, r.ctx)
    val () = x_destroy(r.dpy, r.win)
    val () = if ptr_isnot_null(r.vi) then x_free(r.vi) else ()
    val () = if ptr_isnot_null(r.list) then x_free(r.list) else ()
    val () = x_close(r.dpy)
  in
    ()
  end
end

implement plat_ok(p) =
  case+ p of
  | @PLAT(r) => let
      val k: int = (if ptr_is_null(r.dpy) then 0 else 1): int
    in
      fold@(p); k
    end

implement plat_wh(p, w, h) =
  case+ p of
  | @PLAT(r) => let
      val () = w := r.w
      val () = h := r.h
    in
      fold@(p)
    end

implement plat_set_wh(p, w, h) =
  case+ p of
  | @PLAT(r) => let
      val () = r.w := w
      val () = r.h := h
    in
      fold@(p)
    end

implement plat_running(p) =
  case+ p of
  | @PLAT(r) => let
      val k = (if x_sig_exit() = 1 then Off else r.running): Toggle
    in
      fold@(p); k
    end

implement plat_stop(p) =
  case+ p of
  | @PLAT(r) => let
      val () = r.running := Off
    in
      fold@(p)
    end

implement plat_pending(p) =
  case+ p of
  | @PLAT(r) => let
      val n: int = (if x_sig_exit() = 1 then 0 else x_pending(r.dpy)): int
    in
      fold@(p); n
    end

implement plat_wait(p, ms) =
  case+ p of
  | @PLAT(r) => let
      val () = x_flush(r.dpy)
      val n: int = (if x_sig_exit() = 1 then 0 else x_poll(r.fd, ms)): int
    in
      fold@(p); n
    end

implement plat_ensure_im(p) =
  case+ p of
  | @PLAT(r) => let
      val need: int = (if ptr_is_null(r.ic) then 1 else 0): int
      var im: ptr = r.im
      var ic: ptr = r.ic
      val () = if need = 1 then x_open_im(r.dpy, r.win, im, ic) else ()
      val () = r.im := im
      val () = r.ic := ic
    in
      fold@(p)
    end

implement plat_next(p, ev) =
  case+ p of
  | @PLAT(r) => let
      val () = x_next(r.dpy, r.ic, r.wm, ev)
    in
      fold@(p)
    end

implement plat_swap(p) =
  case+ p of
  | @PLAT(r) => let
      val () = x_swap(r.dpy, r.win)
    in
      fold@(p)
    end

implement plat_own(p, primary) =
  case+ p of
  | @PLAT(r) => let
      val sel = (if primary <> 0 then r.prim else r.clip): ulint
      val () = x_sel_own(r.dpy, sel, r.win)
    in
      fold@(p)
    end

implement plat_paste(p, primary) =
  case+ p of
  | @PLAT(r) => let
      val sel = (if primary <> 0 then r.prim else r.clip): ulint
      val () = x_sel_convert(r.dpy, r.win, sel, r.utf8, r.prop)
    in
      fold@(p)
    end

implement plat_reply(p, ev, data, n) =
  case+ p of
  | @PLAT(r) => let
      val () = x_sel_reply(r.dpy, ev, data, n, r.utf8, r.targets, r.png)
    in
      fold@(p)
    end

implement plat_read(p, ev, dst, cap) =
  case+ p of
  | @PLAT(r) => let
      val n = x_sel_read(r.dpy, r.win, ev_atom2(ev), dst, cap)
    in
      fold@(p); n
    end
