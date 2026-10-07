#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "os/fs.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"

fun u_land(a: int, m: int): int = anth_iand(a, m)

fun byte_at(p: ptr, n: int, i: int): int =
  if i < 0 orelse i >= n then 0
  else mem_byte(p, n, i)

fun utf8_next(p: ptr, n: int, i: &int): int = let
  val b0 = byte_at(p, n, i)
in
  if b0 < 128 then let
    val () = i := i + 1
  in
    b0
  end else if u_land(b0, 224) = 192 andalso i + 1 < n then let
    val b1 = byte_at(p, n, i + 1)
    val () = i := i + 2
  in
    (b0 - 192) * 64 + (b1 - 128)
  end else if u_land(b0, 240) = 224 andalso i + 2 < n then let
    val b1 = byte_at(p, n, i + 1)
    val b2 = byte_at(p, n, i + 2)
    val () = i := i + 3
  in
    (b0 - 224) * 4096 + (b1 - 128) * 64 + (b2 - 128)
  end else let
    val () = i := i + 1
  in
    b0
  end
end

fun scale_val(v: int, num: int, den: int): int =
  if num = 1 andalso den = 1 then v
  else if den = 0 then v
  else idiv(imul(v, num), den)

fun draw_scaled_loop(f: !Font, r: !Rend, x0: int, y0: int, p: ptr, n: int, c: uint, i: int, pen: int, prev: int, snum: int, sden: int): int =
  if i >= n then pen - x0
  else let
    var j: int = i
    val cp = utf8_next(p, n, j)
    val k = font_kern(f, prev, cp)
    var g: gmet = @{ax= 0, bx= 0, top= 0, bw= 0, bh= 0, x0= 0, y0= 0, ok= 0}
    val () = font_glyph(f, r, cp, g)
    val aw = font_atlas_w(f)
    val ah = font_atlas_h(f)
    val asc = font_asc(f)
    val k_bx = scale_val(iadd(k, g.bx), snum, sden)
    val k_ax = scale_val(iadd(k, g.ax), snum, sden)
    val x = iadd(pen, k_bx)
    val y = iadd(y0, scale_val(isub(asc, g.top), snum, sden))
    val bw = scale_val(g.bw, snum, sden)
    val bh = scale_val(g.bh, snum, sden)
    val () =
      if bw > 0 andalso bh > 0 andalso aw > 0 then let
        val u0 = n_i2d(g.x0) / n_i2d(aw)
        val v0 = n_i2d(g.y0) / n_i2d(ah)
        val u1 = n_i2d(iadd(g.x0, g.bw)) / n_i2d(aw)
        val v1 = n_i2d(iadd(g.y0, g.bh)) / n_i2d(ah)
      in
        rend_quad(r, font_tex(f), 1, x, y, bw, bh, u0, v0, u1, v1, c)
      end else ()
  in
    draw_scaled_loop(f, r, x0, y0, p, n, c, j, iadd(pen, k_ax), cp, snum, sden)
  end

implement font_draw(f, r, x, y, p, n, c) =
  if n <= 0 then 0 else draw_scaled_loop(f, r, x, y, p, n, c, 0, x, 0, 1, 1)

implement font_draw_scaled(f, r, x, y, p, n, c, snum, sden) =
  if n <= 0 then 0 else draw_scaled_loop(f, r, x, y, p, n, c, 0, x, 0, (if snum > 0 then snum else 1), (if sden > 0 then sden else 1))

fun width_scaled_loop(f: !Font, r: !Rend, p: ptr, n: int, i: int, pen: int, prev: int, snum: int, sden: int): int =
  if i >= n then pen
  else let
    var j: int = i
    val cp = utf8_next(p, n, j)
    val k = font_kern(f, prev, cp)
    var g: gmet = @{ax= 0, bx= 0, top= 0, bw= 0, bh= 0, x0= 0, y0= 0, ok= 0}
    val () = font_glyph(f, r, cp, g)
    val k_ax = scale_val(iadd(k, g.ax), snum, sden)
  in
    width_scaled_loop(f, r, p, n, j, iadd(pen, k_ax), cp, snum, sden)
  end

implement font_width(f, r, p, n) =
  if n <= 0 then 0 else width_scaled_loop(f, r, p, n, 0, 0, 0, 1, 1)

implement font_width_scaled(f, r, p, n, snum, sden) =
  if n <= 0 then 0 else width_scaled_loop(f, r, p, n, 0, 0, 0, (if snum > 0 then snum else 1), (if sden > 0 then sden else 1))
