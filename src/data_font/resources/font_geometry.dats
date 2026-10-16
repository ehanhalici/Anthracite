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
staload "data_font/resources/font.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/core/glyph_component.sats"
staload "data_text/source/text_source.sats"


#define FONT_OUTLINE_INITIAL_POINTS 3200

(* Quadratic contour expansion and edge construction. *)
staload "data_font/resources/private/font_storage.sats"
staload "data_font/raster/private/font_math.sats"
staload "data_font/resources/private/font_geometry.sats"

extern fun quad_fuel_exhausted(f: !Font, x0: int, y0: int, x1: int, y1: int, x2: int, y2: int, depth: int): void = "mac#anth_die_void"

fun quad_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, x0: int, y0: int, x1: int, y1: int, x2: int, y2: int, depth: int): void =
  if recfuel > 0 then (
    if depth <= 0 then edge_push(f, x0, y0, x2, y2)
    else let
      val mx01 = (x0 + x1) / 2
      val my01 = (y0 + y1) / 2
      val mx12 = (x1 + x2) / 2
      val my12 = (y1 + y2) / 2
      val mx = (mx01 + mx12) / 2
      val my = (my01 + my12) / 2
      val () = quad_with_fuel(recfuel - 1, f, x0, y0, mx01, my01, mx, my, depth - 1)
    in
      quad_with_fuel(recfuel - 1, f, mx, my, mx12, my12, x2, y2, depth - 1)
    end
  ) else quad_fuel_exhausted(f, x0, y0, x1, y1, x2, y2, depth)

fun quad(f: !Font, x0: int, y0: int, x1: int, y1: int, x2: int, y2: int, depth: int): void = quad_with_fuel(airlock_nat(MAX_REC_FUEL), f, x0, y0, x1, y1, x2, y2, depth)

fun push_out(f: !Font, n: int, x: int, y: int, on: int): int =
  if n >= 1500 then n
  else let
    val () = pt_set(f, iadd(FONT_OUTLINE_INITIAL_POINTS, n), x, y, on)
  in
    iadd(n, 1)
  end

fun pix_x(x: int, minx: int, sc: double): int = iround(n_i2d(x - minx) * sc) + 1
fun pix_y(y: int, maxy: int, sc: double): int = iround(n_i2d(maxy - y) * sc) + 1

fun emit_xy(f: !Font, x0: int, y0: int, x1: int, y1: int, minx: int, maxy: int, sc: double): void =
  edge_push(f, pix_x(x0, minx, sc), pix_y(y0, maxy, sc), pix_x(x1, minx, sc), pix_y(y1, maxy, sc))

extern fun rot_copy_fuel_exhausted(f: !Font, n: int, s: int, i: int): void = "mac#anth_die_void"

fun rot_copy_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, n: int, s: int, i: int): void =
  if recfuel > 0 then (
    if i >= n then ()
    else let
      val src = FONT_OUTLINE_INITIAL_POINTS + font_mod(s + i, n)
      val () = pt_set(f, 5200 + i, pt_x(f, src), pt_y(f, src), pt_on(f, src))
    in
      rot_copy_with_fuel(recfuel - 1, f, n, s, i + 1)
    end
  ) else rot_copy_fuel_exhausted(f, n, s, i)

fun rot_copy(f: !Font, n: int, s: int, i: int): void = rot_copy_with_fuel(airlock_nat(MAX_REC_FUEL), f, n, s, i)

extern fun rot_back_fuel_exhausted(f: !Font, n: int, i: int): void = "mac#anth_die_void"

fun rot_back_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, n: int, i: int): void =
  if recfuel > 0 then (
    if i >= n then ()
    else let
      val () = pt_set(f, FONT_OUTLINE_INITIAL_POINTS + i, pt_x(f, 5200 + i), pt_y(f, 5200 + i), pt_on(f, 5200 + i))
    in
      rot_back_with_fuel(recfuel - 1, f, n, i + 1)
    end
  ) else rot_back_fuel_exhausted(f, n, i)

fun rot_back(f: !Font, n: int, i: int): void = rot_back_with_fuel(airlock_nat(MAX_REC_FUEL), f, n, i)

extern fun find_on_fuel_exhausted(f: !Font, n: int, i: int): int = "mac#anth_die_int"

fun find_on_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, n: int, i: int): int =
  if recfuel > 0 then (
    if i >= n then 0
    else if pt_on(f, FONT_OUTLINE_INITIAL_POINTS + i) <> 0 then i else find_on_with_fuel(recfuel - 1, f, n, i + 1)
  ) else find_on_fuel_exhausted(f, n, i)

fun find_on(f: !Font, n: int, i: int): int = find_on_with_fuel(airlock_nat(MAX_REC_FUEL), f, n, i)

fun push_mid(f: !Font, n: int, prev_i: int, curr_i: int): int = let
  val mx = idiv(iadd(pt_x(f, prev_i), pt_x(f, curr_i)), 2)
  val my = idiv(iadd(pt_y(f, prev_i), pt_y(f, curr_i)), 2)
in
  push_out(f, n, mx, my, 1)
end

extern fun contour_loop_fuel_exhausted(f: !Font, k: int, clen: int, a: int, n: int): int = "mac#anth_die_int"

fun contour_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, k: int, clen: int, a: int, n: int): int =
  if recfuel > 0 then (
    if k >= clen then n
    else let
      val curr_i = iadd(a, k)
      val prev_k = font_mod(isub(iadd(k, clen), 1), clen)
      val prev_i = iadd(a, prev_k)
      val curr_on = pt_on(f, curr_i)
      val prev_on = pt_on(f, prev_i)
      val n2 = if ieq(curr_on, 0) andalso ieq(prev_on, 0) then push_mid(f, n, prev_i, curr_i) else n
      val n3 = push_out(f, n2, pt_x(f, curr_i), pt_y(f, curr_i), curr_on)
    in
      contour_loop(recfuel - 1, f, iadd(k, 1), clen, a, n3)
    end
  ) else contour_loop_fuel_exhausted(f, k, clen, a, n)

fun expand_contour(f: !Font, a: int, b: int): int = let
  val clen = isub(b, a) + 1
in
  if ilt(clen, 2) then 0 else contour_loop(airlock_nat(MAX_REC_FUEL), f, 0, clen, a, 0)
end

fun emit_line_at(f: !Font, i: int, n: int, minx: int, maxy: int, sc: double): void = let
  val p0 = font_mod(i, n)
  val p1 = font_mod(iadd(i, 1), n)
in
  emit_xy(f, pt_x(f, iadd(FONT_OUTLINE_INITIAL_POINTS, p0)), pt_y(f, iadd(FONT_OUTLINE_INITIAL_POINTS, p0)),
             pt_x(f, iadd(FONT_OUTLINE_INITIAL_POINTS, p1)), pt_y(f, iadd(FONT_OUTLINE_INITIAL_POINTS, p1)), minx, maxy, sc)
end

fun emit_curve_at(f: !Font, i: int, n: int, minx: int, maxy: int, sc: double): void = let
  val p0 = font_mod(i, n)
  val p1 = font_mod(iadd(i, 1), n)
  val p2 = font_mod(iadd(i, 2), n)
  val x0 = pt_x(f, iadd(FONT_OUTLINE_INITIAL_POINTS, p0))
  val y0 = pt_y(f, iadd(FONT_OUTLINE_INITIAL_POINTS, p0))
  val x1 = pt_x(f, iadd(FONT_OUTLINE_INITIAL_POINTS, p1))
  val y1 = pt_y(f, iadd(FONT_OUTLINE_INITIAL_POINTS, p1))
  val x2 = pt_x(f, iadd(FONT_OUTLINE_INITIAL_POINTS, p2))
  val y2 = pt_y(f, iadd(FONT_OUTLINE_INITIAL_POINTS, p2))
in
  quad(f, pix_x(x0, minx, sc), pix_y(y0, maxy, sc),
          pix_x(x1, minx, sc), pix_y(y1, maxy, sc),
          pix_x(x2, minx, sc), pix_y(y2, maxy, sc), 3)
end

extern fun contour_walk_fuel_exhausted(f: !Font, i: int, n: int, minx: int, maxy: int, sc: double): void = "mac#anth_die_void"

fun contour_walk {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, i: int, n: int, minx: int, maxy: int, sc: double): void =
  if recfuel > 0 then (
    if i >= n then ()
    else if pt_on(f, iadd(FONT_OUTLINE_INITIAL_POINTS, font_mod(iadd(i, 1), n))) <> 0 then let
      val () = emit_line_at(f, i, n, minx, maxy, sc)
    in
      contour_walk(recfuel - 1, f, iadd(i, 1), n, minx, maxy, sc)
    end else let
      val () = emit_curve_at(f, i, n, minx, maxy, sc)
    in
      contour_walk(recfuel - 1, f, iadd(i, 2), n, minx, maxy, sc)
    end
  ) else contour_walk_fuel_exhausted(f, i, n, minx, maxy, sc)

fun walk_contour(f: !Font, n: int, minx: int, maxy: int, sc: double): void =
  if igt(n, 1) then contour_walk(airlock_nat(MAX_REC_FUEL), f, 0, n, minx, maxy, sc) else ()

fun one_contour(f: !Font, a: int, b: int, minx: int, maxy: int, sc: double): void =
  if b < a then ()
  else let
    val n1 = expand_contour(f, a, b)
    val s = (if n1 > 0 then find_on(f, n1, 0) else 0) : int
    val () = if ine(s, 0) then let
      val () = rot_copy(f, n1, s, 0)
    in
      rot_back(f, n1, 0)
    end else ()
  in
    walk_contour(f, n1, minx, maxy, sc)
  end

extern fun contours_fuel_exhausted(f: !Font, ci: int, nends: int, minx: int, maxy: int, sc: double): void = "mac#anth_die_void"

fun contours_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, ci: int, nends: int, minx: int, maxy: int, sc: double): void =
  if recfuel > 0 then (
    if ci >= nends then ()
    else let
      val a = (if ci = 0 then 0 else iadd(end_get(f, isub(ci, 1)), 1)) : int
      val b = end_get(f, ci)
      val () = one_contour(f, a, b, minx, maxy, sc)
    in
      contours_with_fuel(recfuel - 1, f, ci + 1, nends, minx, maxy, sc)
    end
  ) else contours_fuel_exhausted(f, ci, nends, minx, maxy, sc)

implement contours(f, ci, nends, minx, maxy, sc) = contours_with_fuel(airlock_nat(MAX_REC_FUEL), f, ci, nends, minx, maxy, sc)

extern fun bbox_fuel_exhausted(f: !Font, i: int, n: int, minx: &int, miny: &int, maxx: &int, maxy: &int): void = "mac#anth_die_void"

fun bbox_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, i: int, n: int, minx: &int, miny: &int, maxx: &int, maxy: &int): void =
  if recfuel > 0 then (
    if i >= n then ()
    else let
      val x = pt_x(f, i)
      val y = pt_y(f, i)
      val () = if x < minx then minx := x else ()
      val () = if y < miny then miny := y else ()
      val () = if x > maxx then maxx := x else ()
      val () = if y > maxy then maxy := y else ()
    in
      bbox_with_fuel(recfuel - 1, f, i + 1, n, minx, miny, maxx, maxy)
    end
  ) else bbox_fuel_exhausted(f, i, n, minx, miny, maxx, maxy)

implement bbox(f, i, n, minx, miny, maxx, maxy) = bbox_with_fuel(airlock_nat(MAX_REC_FUEL), f, i, n, minx, miny, maxx, maxy)
