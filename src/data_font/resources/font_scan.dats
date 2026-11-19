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

(* 4x vertical sub-scanline + 1/16px horizontal analytical coverage rasterizer. *)
staload "data_font/resources/private/font_storage.sats"
staload "data_font/raster/private/font_math.sats"
staload "data_font/resources/private/font_scan.sats"

macdef SUBPIX_SCALE = 16
macdef SUBSCAN_LINES = 4
macdef MAX_ROW_CROSSINGS = 250

fun collect_cross(f: !Font, y_sub: int, e: int, nc: int): int = let
  val y0 = edge_get(f, e, 1)
  val y1 = edge_get(f, e, 3)
  val x0 = edge_get(f, e, 0)
  val x1 = edge_get(f, e, 2)
  val t = n_i2d(y_sub - y0) / n_i2d(y1 - y0)
  val x = iround(n_i2d(x0) + t * n_i2d(x1 - x0))
  val dir = if y1 > y0 then 1 else ~1
  val () = end_set(f, nc * 2, x)
  val () = end_set(f, nc * 2 + 1, dir)
in
  nc + 1
end

extern fun collect_fuel_exhausted(f: !Font, y: int, e: int, ne: int, nc: int): int = "mac#anth_die_int"

fun collect_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, y_sub: int, e: int, ne: int, nc: int
): int =
  if recursion_fuel_available(recfuel) then (
    if e >= ne orelse nc >= MAX_ROW_CROSSINGS then nc
    else let
      val y0 = edge_get(f, e, 1)
      val y1 = edge_get(f, e, 3)
      val hit = (y0 <= y_sub andalso y1 > y_sub) orelse (y1 <= y_sub andalso y0 > y_sub)
      val nc2 = if y0 = y1 then nc else if hit then collect_cross(f, y_sub, e, nc) else nc
    in
      collect_with_fuel(recfuel - 1, f, y_sub, e + 1, ne, nc2)
    end
  ) else collect_fuel_exhausted(f, y_sub, e, ne, nc)

fun collect(f: !Font, y_sub: int, e: int, ne: int, nc: int): int =
  collect_with_fuel(airlock_nat(MAX_REC_FUEL), f, y_sub, e, ne, nc)

extern fun cross_swap_fuel_exhausted(f: !Font, i: int): void = "mac#anth_die_void"

fun cross_swap_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, i: int): void =
  if recursion_fuel_available(recfuel) then (
    if i <= 0 then ()
    else let
      val x = end_get(f, i * 2)
      val xp = end_get(f, (i - 1) * 2)
    in
      if x >= xp then ()
      else let
        val d = end_get(f, i * 2 + 1)
        val dp = end_get(f, (i - 1) * 2 + 1)
        val () = end_set(f, i * 2, xp)
        val () = end_set(f, i * 2 + 1, dp)
        val () = end_set(f, (i - 1) * 2, x)
        val () = end_set(f, (i - 1) * 2 + 1, d)
      in
        cross_swap_with_fuel(recfuel - 1, f, i - 1)
      end
    end
  ) else cross_swap_fuel_exhausted(f, i)

fun cross_sort_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, n: int, i: int): void =
  if recursion_fuel_available(recfuel) then (
    if i >= n then ()
    else let
      val () = cross_swap_with_fuel(airlock_nat(MAX_REC_FUEL), f, i)
    in
      cross_sort_with_fuel(recfuel - 1, f, n, i + 1)
    end
  ) else ()

fun add_cov_px(f: !Font, px: int, bw: int, amt: int): void =
  if ige(px, 0) andalso ilt(px, bw) andalso igt(amt, 0) then
    cov_set(f, px, imin(64, iadd(cov_get(f, px), amt)))
  else ()

fun fill_mid_cov {n:nat} .<n>. (left: int(n), f: !Font, px: int, bw: int): void =
  if left = 0 then ()
  else let
    val () = add_cov_px(f, px, bw, SUBPIX_SCALE)
  in
    fill_mid_cov(left - 1, f, iadd(px, 1), bw)
  end

fun paint_sub_span(f: !Font, bw: int, prev_x: int, cur_x: int): void = let
  val a = imax(0, prev_x)
  val b = imin(imul(bw, SUBPIX_SCALE), cur_x)
in
  if ilt(a, b) then let
    val px0 = idiv(a, SUBPIX_SCALE)
    val px1 = idiv(isub(b, 1), SUBPIX_SCALE)
  in
    if ieq(px0, px1) then add_cov_px(f, px0, bw, isub(b, a))
    else let
      val left_amt = isub(SUBPIX_SCALE, imod(a, SUBPIX_SCALE))
      val right_amt = isub(b, imul(px1, SUBPIX_SCALE))
      val mid_cnt = imax(0, isub(px1, iadd(px0, 1)))
      val () = add_cov_px(f, px0, bw, left_amt)
      val () = fill_mid_cov(airlock_nat(mid_cnt), f, iadd(px0, 1), bw)
    in
      add_cov_px(f, px1, bw, right_amt)
    end
  end else ()
end

fun wind_sub_row {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, bw: int, n: int, i: int, w: int, prev: int
): void =
  if recursion_fuel_available(recfuel) then (
    if i >= n then ()
    else let
      val x = end_get(f, i * 2)
      val d = end_get(f, i * 2 + 1)
      val () = if w <> 0 then paint_sub_span(f, bw, prev, x) else ()
    in
      wind_sub_row(recfuel - 1, f, bw, n, iadd(i, 1), iadd(w, d), x)
    end
  ) else ()

fun zero_row_cov {n:nat} .<n>. (left: int(n), f: !Font, px: int): void =
  if left = 0 then ()
  else let
    val () = cov_set(f, px, 0)
  in
    zero_row_cov(left - 1, f, iadd(px, 1))
  end

fun scan_sub_lines {n:nat} .<n>. (
  left: int(n), f: !Font, bw: int, py: int, sy: int, ne: int
): void =
  if left = 0 then ()
  else let
    val y_sub = iadd(imul(py, SUBPIX_SCALE), iadd(imul(sy, 4), 2))
    val nc = collect(f, y_sub, 0, ne, 0)
    val () = cross_sort_with_fuel(airlock_nat(MAX_REC_FUEL), f, nc, 1)
    val () = wind_sub_row(airlock_nat(MAX_REC_FUEL), f, bw, nc, 0, 0, 0)
  in
    scan_sub_lines(left - 1, f, bw, py, iadd(sy, 1), ne)
  end

fun cov_to_alpha(f: !Font, cov_val: int): int = let
  val a0 = imin(255, idiv(iadd(imul(cov_val, 255), 32), 64))
in
  if ile(font_get_px(f), 18) andalso igt(a0, 0) then
    imin(255, iadd(a0, idiv(imul(a0, isub(255, a0)), 640)))
  else a0
end

fun emit_row_to_atlas {n:nat} .<n>. (
  left: int(n), f: !Font, x0: int, y0: int, py: int, px: int
): void =
  if left = 0 then ()
  else let
    val alpha = cov_to_alpha(f, cov_get(f, px))
    val () = atlas_set(f, iadd(x0, px), iadd(y0, py), alpha)
  in
    emit_row_to_atlas(left - 1, f, x0, y0, py, iadd(px, 1))
  end

fun scan_atlas_rows {n:nat} .<n>. (
  left: int(n), f: !Font, x0: int, y0: int, bw: int, py: int, ne: int
): void =
  if left = 0 then ()
  else let
    val () = zero_row_cov(airlock_nat(imax(0, bw)), f, 0)
    val () = scan_sub_lines(airlock_nat(SUBSCAN_LINES), f, bw, py, 0, ne)
    val () = emit_row_to_atlas(airlock_nat(imax(0, bw)), f, x0, y0, py, 0)
  in
    scan_atlas_rows(left - 1, f, x0, y0, bw, iadd(py, 1), ne)
  end

implement raster_scan_to_atlas(f, x0, y0, bw, bh) =
  if ile(bw, 0) orelse ile(bh, 0) then ()
  else let
    val ne = font_get_edge_count(f)
  in
    scan_atlas_rows(airlock_nat(bh), f, x0, y0, bw, 0, ne)
  end
