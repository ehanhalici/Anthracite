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



(* Scanline coverage and supersample reduction. *)
staload "data_font/private/font_storage.sats"
staload "data_font/private/font_math.sats"
staload "data_font/private/font_scan.sats"

fun collect_cross(f: !Font, y: int, e: int, nc: int): int = let
  val y0 = edge_get(f, e, 1)
  val y1 = edge_get(f, e, 3)
  val x0 = edge_get(f, e, 0)
  val x1 = edge_get(f, e, 2)
  val den = n_i2d(y1 - y0)
  val t = (n_i2d(y) - n_i2d(y0)) / den
  val x = iround(n_i2d(x0) + t * n_i2d(x1 - x0))
  val dir = if y1 > y0 then 1 else ~1
  val () = end_set(f, nc * 2, x)
  val () = end_set(f, nc * 2 + 1, dir)
in
  nc + 1
end

extern fun collect_exh(f: !Font, y: int, e: int, ne: int, nc: int): int = "mac#anth_die_int"

fun collect_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, y: int, e: int, ne: int, nc: int): int =
  if recfuel > 0 then (
    if e >= ne orelse nc >= 100 then nc
    else let
      val y0 = edge_get(f, e, 1)
      val y1 = edge_get(f, e, 3)
      val hit = (y0 <= y andalso y1 > y) orelse (y1 <= y andalso y0 > y)
      val nc2 = if y0 = y1 then nc else if hit then collect_cross(f, y, e, nc) else nc
    in
      collect_m(recfuel - 1, f, y, e + 1, ne, nc2)
    end
  ) else collect_exh(f, y, e, ne, nc)

fun collect(f: !Font, y: int, e: int, ne: int, nc: int): int = collect_m(airlock_nat(MAX_REC_FUEL), f, y, e, ne, nc)

extern fun cross_swap_exh(f: !Font, i: int): void = "mac#anth_die_void"

fun cross_swap_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, i: int): void =
  if recfuel > 0 then (
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
        cross_swap_m(recfuel - 1, f, i - 1)
      end
    end
  ) else cross_swap_exh(f, i)

fun cross_swap(f: !Font, i: int): void = cross_swap_m(airlock_nat(MAX_REC_FUEL), f, i)

extern fun cross_sort_exh(f: !Font, n: int, i: int): void = "mac#anth_die_void"

fun cross_sort_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, n: int, i: int): void =
  if recfuel > 0 then (
    if i >= n then ()
    else let
      val () = cross_swap(f, i)
    in
      cross_sort_m(recfuel - 1, f, n, i + 1)
    end
  ) else cross_sort_exh(f, n, i)

fun cross_sort(f: !Font, n: int, i: int): void = cross_sort_m(airlock_nat(MAX_REC_FUEL), f, n, i)

extern fun paint_pix_exh(f: !Font, x: int, y: int, sw: int, b: int): void = "mac#anth_die_void"

fun paint_pix {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, x: int, y: int, sw: int, b: int): void =
  if recfuel > 0 then (
    if x >= b then ()
    else let
      val () = cov_set(f, y * sw + x, 255)
    in
      paint_pix(recfuel - 1, f, x + 1, y, sw, b)
    end
  ) else paint_pix_exh(f, x, y, sw, b)

fun paint(f: !Font, sw: int, y: int, x0: int, x1: int): void = let
  val a = (if x0 < 0 then 0 else x0) : int
  val b = (if x1 > sw then sw else x1) : int
in
  if a < b andalso y >= 0 andalso y < 256 then paint_pix(airlock_nat(MAX_REC_FUEL), f, a, y, sw, b) else ()
end

extern fun wind_exh(f: !Font, sw: int, y: int, n: int, i: int, w: int, prev: int): void = "mac#anth_die_void"

fun wind_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, sw: int, y: int, n: int, i: int, w: int, prev: int): void =
  if recfuel > 0 then (
    if i >= n then ()
    else let
      val x = end_get(f, i * 2)
      val d = end_get(f, i * 2 + 1)
      val () = if w <> 0 then paint(f, sw, y, prev, x) else ()
    in
      wind_m(recfuel - 1, f, sw, y, n, i + 1, w + d, x)
    end
  ) else wind_exh(f, sw, y, n, i, w, prev)

fun wind(f: !Font, sw: int, y: int, n: int, i: int, w: int, prev: int): void = wind_m(airlock_nat(MAX_REC_FUEL), f, sw, y, n, i, w, prev)

extern fun scan_rows_exh(f: !Font, sw: int, sh: int, y: int): void = "mac#anth_die_void"

fun scan_rows_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, sw: int, sh: int, y: int): void =
  if recfuel > 0 then (
    if y >= sh then ()
    else let
      val ne = f_get_nedges(f)
      val nc = collect(f, y, 0, ne, 0)
      val () = cross_sort(f, nc, 1)
      val () = wind(f, sw, y, nc, 0, 0, 0)
    in
      scan_rows_m(recfuel - 1, f, sw, sh, y + 1)
    end
  ) else scan_rows_exh(f, sw, sh, y)

implement scan_rows(f, sw, sh, y) = scan_rows_m(airlock_nat(MAX_REC_FUEL), f, sw, sh, y)

extern fun blit_col_exh(f: !Font, x: int, y: int, x0: int, y0: int, sw: int, bw: int): void = "mac#anth_die_void"

fun blit_col {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, x: int, y: int, x0: int, y0: int, sw: int, bw: int): void =
  if recfuel > 0 then (
    if x >= bw then ()
    else let
      val i00 = (y * 2) * sw + x * 2
      val s = cov_get(f, i00) + cov_get(f, i00 + 1) + cov_get(f, i00 + sw) + cov_get(f, i00 + sw + 1)
      val () = atlas_set(f, x0 + x, y0 + y, (s / 4): int)
    in
      blit_col(recfuel - 1, f, x + 1, y, x0, y0, sw, bw)
    end
  ) else blit_col_exh(f, x, y, x0, y0, sw, bw)

extern fun blit_exh(f: !Font, x0: int, y0: int, sw: int, bw: int, bh: int, y: int): void = "mac#anth_die_void"

fun blit_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, x0: int, y0: int, sw: int, bw: int, bh: int, y: int): void =
  if recfuel > 0 then (
    if y >= bh then ()
    else let
      val () = blit_col(airlock_nat(MAX_REC_FUEL), f, 0, y, x0, y0, sw, bw)
    in
      blit_m(recfuel - 1, f, x0, y0, sw, bw, bh, y + 1)
    end
  ) else blit_exh(f, x0, y0, sw, bw, bh, y)

implement blit(f, x0, y0, sw, bw, bh, y) = blit_m(airlock_nat(MAX_REC_FUEL), f, x0, y0, sw, bw, bh, y)
