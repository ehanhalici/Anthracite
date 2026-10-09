%{#
#include "core_platform/x11.cats"
%}

abst@ype event = $extype"anth_event"

macdef EV_CLOSE = $extval(int, "ANTH_EV_CLOSE")
macdef EV_RESIZE = $extval(int, "ANTH_EV_RESIZE")
macdef EV_KEY = $extval(int, "ANTH_EV_KEY")
macdef EV_DOWN = $extval(int, "ANTH_EV_DOWN")
macdef EV_UP = $extval(int, "ANTH_EV_UP")
macdef EV_MOTION = $extval(int, "ANTH_EV_MOTION")
macdef EV_WHEEL = $extval(int, "ANTH_EV_WHEEL")
macdef EV_SEL_REQ = $extval(int, "ANTH_EV_SEL_REQ")
macdef EV_SEL_NOTIFY = $extval(int, "ANTH_EV_SEL_NOTIFY")

datatype Ev =
  | EvNone
  | EvClose
  | EvResize
  | EvKey
  | EvDown
  | EvUp
  | EvMotion
  | EvWheel
  | EvSelReq
  | EvSelNotify

fun event_of(n: int): Ev
fun is_ev(a: Ev, b: Ev): bool

fun ev_kind(ev: &event): int = "mac#anth_ev_kind"

macdef KEY_LEFT = $extval(int, "ANTH_KEY_LEFT")
macdef KEY_RIGHT = $extval(int, "ANTH_KEY_RIGHT")
macdef KEY_UP = $extval(int, "ANTH_KEY_UP")
macdef KEY_DOWN = $extval(int, "ANTH_KEY_DOWN")
macdef KEY_BACKSPACE = $extval(int, "ANTH_KEY_BACKSPACE")
macdef KEY_DELETE = $extval(int, "ANTH_KEY_DELETE")
macdef KEY_HOME = $extval(int, "ANTH_KEY_HOME")
macdef KEY_END = $extval(int, "ANTH_KEY_END")
macdef KEY_RETURN = $extval(int, "ANTH_KEY_RETURN")
macdef KEY_TAB = $extval(int, "ANTH_KEY_TAB")
macdef KEY_ESCAPE = $extval(int, "ANTH_KEY_ESCAPE")
macdef KEY_PAGE_UP = $extval(int, "ANTH_KEY_PAGE_UP")
macdef KEY_PAGE_DOWN = $extval(int, "ANTH_KEY_PAGE_DOWN")

datatype Key =
  | KeyLeft
  | KeyRight
  | KeyUp
  | KeyDown
  | KeyBackspace
  | KeyDelete
  | KeyHome
  | KeyEnd
  | KeyReturn
  | KeyTab
  | KeyEscape
  | KeyPageUp
  | KeyPageDown

fun key_id(k: Key): int

datatype Btn = BtnLeft | BtnRight | BtnWheelUp | BtnOther

fun button_of(n: int): Btn
fun is_btn(a: Btn, b: Btn): bool

fun x_err_install(): void = "mac#anth_xerr_install"
fun x_open(name: ptr): ptr = "mac#XOpenDisplay"
fun x_default_screen(dpy: ptr): int = "mac#XDefaultScreen"
fun x_root(dpy: ptr, screen: int): ulint = "mac#XRootWindow"
fun x_create_colormap(dpy: ptr, w: ulint, vis: ptr, alloc: int): ulint = "mac#XCreateColormap"
fun x_store_name(dpy: ptr, w: ulint, name: string): void = "mac#XStoreName"
fun x_intern(dpy: ptr, name: string, only: int): ulint = "mac#XInternAtom"
fun x_map(dpy: ptr, w: ulint): void = "mac#XMapWindow"
fun x_flush(dpy: ptr): void = "mac#XFlush"
fun x_sync(dpy: ptr, discard: int): void = "mac#XSync"
fun x_pending(dpy: ptr): int = "mac#XPending"
fun x_destroy(dpy: ptr, w: ulint): void = "mac#XDestroyWindow"
fun x_close(dpy: ptr): void = "mac#XCloseDisplay"
fun x_free(p: ptr): void = "mac#XFree"
fun x_alloc_none(): int = "mac#anth_alloc_none"

fun x_choose_fb(dpy: ptr, screen: int, fb: &ptr >> _, visual: &ptr >> _,
  vi: &ptr >> _, list: &ptr >> _, depth: &int >> _): int = "mac#anth_choose_fb"
fun x_ulint0(): ulint = "mac#anth_ulint0"
fun x_create_window(dpy: ptr, root: ulint, vis: ptr, depth: int,
  x: int, y: int, w: int, h: int, cmap: ulint): ulint = "mac#anth_create_window"
fun x_wm(dpy: ptr, win: ulint, atom: ulint): void = "mac#anth_wm"
fun x_create_ctx(dpy: ptr, fb: ptr): ptr = "mac#anth_create_ctx"
fun x_make_current(dpy: ptr, win: ulint, ctx: ptr): int = "mac#anth_make_current"
fun x_make_current_drop(dpy: ptr, win: ulint, ctx: ptr): void = "mac#anth_make_current"
fun x_swap(dpy: ptr, win: ulint): void = "mac#anth_swap"
fun x_destroy_ctx(dpy: ptr, ctx: ptr): void = "mac#anth_destroy_ctx"
fun x_open_im(dpy: ptr, win: ulint, im: &ptr >> _, ic: &ptr >> _): void = "mac#anth_open_im"
fun x_close_im(im: ptr, ic: ptr): void = "mac#anth_close_im"
fun x_fd(dpy: ptr): int = "mac#ConnectionNumber"
fun x_poll(fd: int, ms: int): int = "mac#anth_poll"
fun x_next(dpy: ptr, ic: ptr, wm: ulint, ev: &event? >> event): void = "mac#anth_next"

fun ev_x(ev: &event): int = "mac#anth_ev_x"
fun ev_y(ev: &event): int = "mac#anth_ev_y"
fun ev_w(ev: &event): int = "mac#anth_ev_w"
fun ev_h(ev: &event): int = "mac#anth_ev_h"
fun ev_button(ev: &event): int = "mac#anth_ev_button"
fun ev_mods(ev: &event): int = "mac#anth_ev_mods"
fun ev_atom2(ev: &event): ulint = "mac#anth_ev_atom2"
fun ev_text(ev: &event, dst: ptr, n: int): int = "mac#anth_ev_text"
fun ev_key_char(ev: &event): int = "mac#anth_ev_key_char"

fun x_key_is(ev: &event, id: int): int = "mac#anth_key_is"
fun mod_ctrl(): int = "mac#anth_mod_ctrl"
fun mod_shift(): int = "mac#anth_mod_shift"

fun x_install_signals(): void = "mac#anth_install_signals"
fun x_sig_exit(): int = "mac#anth_sig_received"

fun x_sel_reply(dpy: ptr, ev: &event, data: ptr, n: int,
  utf8: ulint, targets: ulint, png: ulint): void = "mac#anth_sel_reply"
fun x_sel_read(dpy: ptr, win: ulint, prop: ulint, dst: ptr, cap: int): int = "mac#anth_sel_read"
fun x_sel_convert(dpy: ptr, win: ulint, sel: ulint, target: ulint, prop: ulint): void = "mac#anth_sel_convert"
fun x_sel_own(dpy: ptr, sel: ulint, win: ulint): void = "mac#anth_sel_own"
