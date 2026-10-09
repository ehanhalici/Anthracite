#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "core_platform/platform.sats"
staload "core_platform/x11.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "data_font/font.sats"
staload "data_ast/doc.sats"
staload "data_image/image.sats"
staload "ui_workspace/ui.sats"

fun is0(n: int): bool = n = 0

fun plat_read_buf(p: !Plat, ev: &event, dst: !Buf, cap: int): int =
  plat_read(p, ev, buf_ptr(dst), cap)

fun ms_between(a: lint, b: lint): int = anth_ms(a, b)

extern fun drain_exh(p: !Plat, a: !App, f: !Font, r: !Rend): void = "mac#anth_die_void"

fun drain_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), p: !Plat, a: !App, f: !Font, r: !Rend): void =
  if recfuel > 0 then (
    if plat_pending(p) = 0 then ()
    else let
      var ev: event
      var w: int = 0
      var h: int = 0
      val () = plat_next(p, ev)
      val () = plat_wh(p, w, h)
      val k = event_of(ev_kind(ev))
      val () = if is_ev(k, EvKey) then plat_ensure_im(p) else ()
      val () = if is_ev(k, EvClose) then plat_stop(p) else ()
      val () = if is_ev(k, EvResize) then plat_set_wh(p, ev_w(ev), ev_h(ev)) else ()
      val () = app_event(a, p, f, r, ev, w, h)
    in
      if is_off(plat_running(p)) then () else drain_m(recfuel - 1, p, a, f, r)
    end
  ) else drain_exh(p, a, f, r)

fun drain(p: !Plat, a: !App, f: !Font, r: !Rend): void = drain_m(airlock_nat(MAX_REC_FUEL), p, a, f, r)

extern fun frame_exh(p: !Plat, a: !App, f: !Font, r: !Rend, loaded: bool): void = "mac#anth_die_void"

fun frame_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), p: !Plat, a: !App, f: !Font, r: !Rend, loaded: bool): void =
  if recfuel > 0 then (
    if is_off(plat_running(p)) then ()
    else let
      val () = drain(p, a, f, r)
    in
      if is_off(plat_running(p)) then ()
      else let
        val loaded2 = if not(loaded) then font_load_default(f) else loaded
        var w: int = 0
        var h: int = 0
        val () = plat_wh(p, w, h)
        val () = rend_begin(r, w, h)
        val () = app_draw(a, f, r, w, h)
        val () = rend_flush(r)
        val () = plat_swap(p)
        val () = seen_int(plat_wait(p, ~1))
      in
        frame_m(recfuel - 1, p, a, f, r, loaded2)
      end
    end
  ) else frame_exh(p, a, f, r, loaded)

fun frame(p: !Plat, a: !App, f: !Font, r: !Rend, loaded: bool): void = frame_m(airlock_nat(MAX_REC_FUEL), p, a, f, r, loaded)

fun take_sel(p: !Plat, ev: &event, data: ptr, n: int, dst: &Buf >> _, got: &int >> _): void = let
  val k = event_of(ev_kind(ev))
in
  if is_ev(k, EvSelReq) then let
    val () = plat_reply(p, ev, data, n)
    val () = touch_dst(dst)
  in
    ()
  end else if is_ev(k, EvSelNotify) then let
    val cap = buf_cap(dst)
    val nr = plat_read_buf(p, ev, dst, cap)
    val () = buf_set_len(dst, if nr > 0 then nr else 0)
  in
    got := nr
  end else touch_dst(dst)
end

and touch_dst(dst: &Buf >> _): void = ()

extern fun clip_round_exh(p: !Plat, data: ptr, n: int, dst: &Buf >> _, got: &int >> _, spins: int): void = "mac#anth_die_void"

fun clip_round_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), p: !Plat, data: ptr, n: int, dst: &Buf >> _, got: &int >> _, spins: int): void =
  if recfuel > 0 then (
    if spins <= 0 then touch_dst(dst)
    else if got > 0 then touch_dst(dst)
    else if plat_pending(p) = 0 then let
      val () = seen_int(plat_wait(p, 20))
    in
      clip_round_m(recfuel - 1, p, data, n, dst, got, spins - 1)
    end else let
      var ev: event
      val () = plat_next(p, ev)
      val () = take_sel(p, ev, data, n, dst, got)
    in
      clip_round_m(recfuel - 1, p, data, n, dst, got, spins - 1)
    end
  ) else clip_round_exh(p, data, n, dst, got, spins)

fun clip_round(p: !Plat, data: ptr, n: int, dst: &Buf >> _, got: &int >> _, spins: int): void = clip_round_m(airlock_nat(MAX_REC_FUEL), p, data, n, dst, got, spins)

extern fun same_text_exh(b: !Buf, s: string, i: int): int = "mac#anth_die_int"

fun same_text_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, s: string, i: int): int =
  if recfuel > 0 then (
    if i >= c_strlen(s) then 1
    else if buf_get(b, i) <> c_str_byte(s, i) then 0
    else same_text_m(recfuel - 1, b, s, i + 1)
  ) else same_text_exh(b, s, i)

fun same_text(b: !Buf, s: string, i: int): int = same_text_m(airlock_nat(MAX_REC_FUEL), b, s, i)

fun clip_match(b: !Buf, s: string, n: int): int =
  if buf_len(b) <> n then 0 else same_text(b, s, 0)

fun vault_at(cwd: !Buf, use_arg: bool): string =
  if use_arg then let
    val () = seen_buf(cwd)
  in
    c_argv(1)
  end else ""

fun run_core_selftests(r: !Rend): void = let
  val n = font_selftest(r)
  val m = doc_selftest()
  val q = img_selftest()
  val u = app_selftest(r)
  val () = println! ("font_selftest=", n)
  val () = println! ("doc_selftest=", m)
  val () = println! ("img_selftest=", q)
in
  println! ("app_selftest=", u)
end

fun print_budget_metrics(start: int, rss: int, live: int, waited: int, clip_ok: int): void = let
  val poll_ok = if waited >= 80 then 1 else 0
  val rss_ok = if live > 0 andalso live < 12582912 then 1 else 0
  val () = print("budget start_ms=")
  val () = print_int(start)
  val () = print(" rss_kb=")
  val () = print_int(rss)
  val () = print(" live=")
  val () = print_int(live)
  val () = print(" poll_ms=")
  val () = print_int(waited)
  val () = print(" clip=")
  val () = print_int(clip_ok)
  val () = print(" poll_ok=")
  val () = print_int(poll_ok)
  val () = print(" rss_ok=")
  val () = print_int(rss_ok)
in
  print_newline()
end

extern fun drain_pending_exh(p: !Plat): void = "mac#anth_die_void"

fun drain_pending_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), p: !Plat): void =
  if recfuel > 0 then (
    if plat_pending(p) = 0 then ()
    else let
      var ev: event
      val () = plat_next(p, ev)
    in
      drain_pending_m(recfuel - 1, p)
    end
  ) else drain_pending_exh(p)

fun drain_pending(p: !Plat): void = drain_pending_m(airlock_nat(MAX_REC_FUEL), p)

fun check_clip_self(p: !Plat): int = let
  val text = "anthracite"
  var dst = buf_make(64)
  var got: int = 0
  val () = plat_own(p, false)
  val () = plat_paste(p, false)
  val () = clip_round(p, c_str_ptr(text), c_strlen(text), dst, got, 40)
  val clip_ok = clip_match(dst, text, got)
  val () = buf_free(dst)
  val () = drain_pending(p)
in
  clip_ok
end

fun draw_self_frame(p: !Plat, r: !Rend, f: !Font): void = let
  var w: int = 0
  var h: int = 0
  val () = plat_wh(p, w, h)
  val () = rend_begin(r, w, h)
  val () = rend_rect(r, 0, 0, w, h, col_bg())
  val () = seen_int(font_draw(f, r, 24, 48, c_str_ptr("Anthracite"), 10, col_text()))
  val () = rend_flush(r)
  val () = plat_swap(p)
in
end

fun self_poll_ms(p: !Plat): int = let
  val tw = mono_ns()
  val () = seen_int(plat_wait(p, 100))
  val tw2 = mono_ns()
in
  ms_between(tw, tw2)
end

fun run_self(p: !Plat, r: !Rend, t0: lint): void = let
  val f = font_open()
  val () = draw_self_frame(p, r, f)
  val t1 = mono_ns()
  val start = ms_between(t0, t1)
  val () = run_core_selftests(r)
  val clip_ok = check_clip_self(p)
  val waited = self_poll_ms(p)
  val rss = rss_kb()
  val live = mem_live()
  val () = print_budget_metrics(start, rss, live, waited, clip_ok)
  val () = font_free(f)
in
  plat_stop(p)
end

fun run_app(p: !Plat, r: !Rend): void = let
  var cwd = buf_make(4096)
  val nc = c_cwd_buf(cwd, 4095)
  val nclen = if nc > 0 then nc else 0
  val () = buf_set_len(cwd, nclen)
  val () = buf_set(cwd, nclen, 0)
  val use_arg = c_argc() > 1
  val vault = vault_at(cwd, use_arg)
  val a = app_open(vault)
  val () = buf_free(cwd)
  val f = font_open()
  val loaded = font_load_default(f)
  val () = frame(p, a, f, r, loaded)
  val () = font_free(f)
in
  app_free(a)
end

fun launch(p: !Plat, r: !Rend, t0: lint, selftest: bool): void =
  if selftest then run_self(p, r, t0) else run_app(p, r)

implement main0() = let
  val t0 = mono_ns()
  val p = plat_open()
in
  if not(plat_ok(p)) then let
    val () = println! ("event=display_error status=failed error=cannot_open_display")
    val () = plat_close(p)
  in
    ()
  end else let
    val r = rend_open()
    val selftest = c_argc() > 1 andalso is0(c_strcmp(c_argv(1), "--selftest"))
    val () = launch(p, r, t0, selftest)
    val () = rend_close(r)
    val () = plat_close(p)
  in
    ()
  end
end
