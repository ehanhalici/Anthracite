#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "core_render/gl.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"
staload "data_font/sfnt.sats"
staload "data_font/glyph_component.sats"
staload "data_text/text_source.sats"


#define MAXP 3000
#define OUT0 3200

(* Decoding simple TrueType contours. *)
staload "data_font/private/font_storage.sats"
staload "data_font/private/font_math.sats"
staload "data_font/private/font_outline_simple.sats"

fun delta_of(short: int, same: int, byte: int, word: int): int =
  if short = 1 then (if same = 1 then byte else isub(0, byte)) else (if same = 1 then 0 else word)
fun adv_p(short: int, same: int, p: int): int =
  if short = 1 then iadd(p, 1) else if same = 1 then p else iadd(p, 2)

extern fun read_ends_exh(f: !Font, i: int, ncont: int, p: int, base: int, eb: int): int = "mac#anth_die_int"

fun read_ends_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, i: int, ncont: int, p: int, base: int, eb: int): int =
  if recfuel > 0 then (
    if i >= ncont then p
    else let
      val e = file_u16(f, p)
      val () = end_set(f, eb + i, base + e)
    in
      read_ends_m(recfuel - 1, f, i + 1, ncont, p + 2, base, eb)
    end
  ) else read_ends_exh(f, i, ncont, p, base, eb)

fun read_ends(f: !Font, i: int, ncont: int, p: int, base: int, eb: int): int = read_ends_m(airlock_nat(MAX_REC_FUEL), f, i, ncont, p, base, eb)

extern fun flag_put_exh(f: !Font, k: int, rep: int, i: int, np: int, base: int, flg: int): void = "mac#anth_die_void"

fun flag_put {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, k: int, rep: int, i: int, np: int, base: int, flg: int): void =
  if recfuel > 0 then (
    if k >= rep orelse i + k >= np then ()
    else let
      val () = set_fl(f, iadd(iadd(base, i), k), flg)
    in
      flag_put(recfuel - 1, f, iadd(k, 1), rep, i, np, base, flg)
    end
  ) else flag_put_exh(f, k, rep, i, np, base, flg)

extern fun flag_run_exh(f: !Font, i: int, np: int, p: int, base: int): int = "mac#anth_die_int"

fun flag_run_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, i: int, np: int, p: int, base: int): int =
  if recfuel > 0 then (
    if i >= np then p
    else let
      val flg = file_u8(f, p)
      val rep0: int = (if bit(flg, 8) = 1 then file_u8(f, p + 1) else 0): int
      val rep: int = (if rep0 < 0 then 1 else rep0 + 1): int
      val p2 = (if bit(flg, 8) = 1 then iadd(p, 2) else iadd(p, 1)) : int
      val () = flag_put(airlock_nat(MAX_REC_FUEL), f, 0, rep, i, np, base, flg)
      val step = (if iadd(i, rep) > np then isub(np, i) else rep) : int
    in
      flag_run_m(recfuel - 1, f, iadd(i, step), np, p2, base)
    end
  ) else flag_run_exh(f, i, np, p, base)

fun flag_run(f: !Font, i: int, np: int, p: int, base: int): int = flag_run_m(airlock_nat(MAX_REC_FUEL), f, i, np, p, base)

extern fun xs_loop_exh(f: !Font, i: int, np: int, p: int, x: int, base: int): int = "mac#anth_die_int"

fun xs_loop_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, i: int, np: int, p: int, x: int, base: int): int =
  if recfuel > 0 then (
    if i >= np then p
    else let
      val flg = pt_on(f, base + i)
      val short = bit(flg, 2)
      val same = bit(flg, 16)
      val dx = delta_of(short, same, file_u8(f, p), file_i16(f, p))
      val p2 = adv_p(short, same, p)
      val () = set_x(f, iadd(base, i), iadd(x, dx))
    in
      xs_loop_m(recfuel - 1, f, iadd(i, 1), np, p2, iadd(x, dx), base)
    end
  ) else xs_loop_exh(f, i, np, p, x, base)

fun xs_loop(f: !Font, i: int, np: int, p: int, x: int, base: int): int = xs_loop_m(airlock_nat(MAX_REC_FUEL), f, i, np, p, x, base)

extern fun ys_loop_exh(f: !Font, i: int, np: int, p: int, y: int, base: int, dx: double, dy: double, xx: double, yy: double, xy: double, yx: double): void = "mac#anth_die_void"

fun ys_loop_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, i: int, np: int, p: int, y: int, base: int, dx: double, dy: double, xx: double, yy: double, xy: double, yx: double): void =
  if recfuel > 0 then (
    if i >= np then ()
    else let
      val flg = pt_on(f, base + i)
      val short = bit(flg, 4)
      val same = bit(flg, 32)
      val dyb = delta_of(short, same, file_u8(f, p), file_i16(f, p))
      val p2 = adv_p(short, same, p)
      val rx = pt_x(f, iadd(base, i))
      val ry = iadd(y, dyb)
      val nx = iround(xx * n_i2d(rx) + xy * n_i2d(ry) + dx)
      val ny = iround(yx * n_i2d(rx) + yy * n_i2d(ry) + dy)
      val () = pt_set(f, iadd(base, i), nx, ny, bit(flg, 1))
    in
      ys_loop_m(recfuel - 1, f, iadd(i, 1), np, p2, ry, base, dx, dy, xx, yy, xy, yx)
    end
  ) else ys_loop_exh(f, i, np, p, y, base, dx, dy, xx, yy, xy, yx)

fun ys_loop(f: !Font, i: int, np: int, p: int, y: int, base: int, dx: double, dy: double, xx: double, yy: double, xy: double, yx: double): void = ys_loop_m(airlock_nat(MAX_REC_FUEL), f, i, np, p, y, base, dx, dy, xx, yy, xy, yx)

fun decode_points(f: !Font, p2: int, base: int, np: int, dx: double, dy: double, xx: double, yy: double, xy: double, yx: double): void = let
  val p3 = flag_run(f, 0, np, p2, base)
  val p4 = xs_loop(f, 0, np, p3, 0, base)
in
  ys_loop(f, 0, np, p4, 0, base, dx, dy, xx, yy, xy, yx)
end

implement decode_simple(f, p0, ncont, dx, dy, xx, yy, xy, yx) = let
  val base = f_get_npts(f)
  val eb = f_get_nends(f)
in
  if ncont <= 0 then ()
  else let
    val p1 = read_ends(f, 0, ncont, p0, base, eb)
    val ninstr = file_u16(f, p1)
    val p2 = p1 + 2 + ninstr
    val np = end_get(f, eb + ncont - 1) - base + 1
  in
    if np <= 0 orelse np > MAXP orelse base + np >= OUT0 then ()
    else let
      val () = decode_points(f, p2, base, np, dx, dy, xx, yy, xy, yx)
      val () = f_set_nends(f, eb + ncont)
      val () = f_set_npts(f, base + np)
    in
    end
  end
end
