#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "core_platform/platform.sats"
staload "core_platform/x11.sats"
staload "core_runtime/clipboard.sats"

fun plat_read_buf(p: !Plat, ev: &event, dst: !Buf, cap: int): int =
  plat_read(p, ev, buf_ptr(dst), cap)

fun touch_dst(dst: &Buf >> _): void = ()

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

extern fun clip_round_fuel_exhausted(p: !Plat, data: ptr, n: int, dst: &Buf >> _, got: &int >> _, spins: int): void = "mac#anth_die_void"

fun clip_round_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), p: !Plat, data: ptr, n: int, dst: &Buf >> _, got: &int >> _, spins: int): void =
  if recfuel > 0 then (
    if spins <= 0 then touch_dst(dst)
    else if got > 0 then touch_dst(dst)
    else if plat_pending(p) = 0 then let
      val () = seen_int(plat_wait(p, 20))
    in
      clip_round_with_fuel(recfuel - 1, p, data, n, dst, got, spins - 1)
    end else let
      var ev: event
      val () = plat_next(p, ev)
      val () = take_sel(p, ev, data, n, dst, got)
    in
      clip_round_with_fuel(recfuel - 1, p, data, n, dst, got, spins - 1)
    end
  ) else clip_round_fuel_exhausted(p, data, n, dst, got, spins)

fun clip_round(p: !Plat, data: ptr, n: int, dst: &Buf >> _, got: &int >> _, spins: int): void =
  clip_round_with_fuel(airlock_nat(MAX_REC_FUEL), p, data, n, dst, got, spins)

extern fun same_text_fuel_exhausted(b: !Buf, s: string, i: int): int = "mac#anth_die_int"

fun same_text_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, s: string, i: int): int =
  if recfuel > 0 then (
    if i >= c_strlen(s) then 1
    else if buf_get(b, i) <> c_str_byte(s, i) then 0
    else same_text_with_fuel(recfuel - 1, b, s, i + 1)
  ) else same_text_fuel_exhausted(b, s, i)

fun same_text(b: !Buf, s: string, i: int): int =
  same_text_with_fuel(airlock_nat(MAX_REC_FUEL), b, s, i)

fun clip_match(b: !Buf, s: string, n: int): int =
  if buf_len(b) <> n then 0 else same_text(b, s, 0)

extern fun drain_pending_fuel_exhausted(p: !Plat): void = "mac#anth_die_void"

fun drain_pending_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), p: !Plat): void =
  if recfuel > 0 then (
    if plat_pending(p) = 0 then ()
    else let
      var ev: event
      val () = plat_next(p, ev)
    in
      drain_pending_with_fuel(recfuel - 1, p)
    end
  ) else drain_pending_fuel_exhausted(p)

fun drain_pending(p: !Plat): void =
  drain_pending_with_fuel(airlock_nat(MAX_REC_FUEL), p)

implement clipboard_selftest(p) = let
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
