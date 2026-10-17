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



(* TrueType glyph rasterization orchestration. *)
staload "data_font/resources/private/font_geometry.sats"
staload "data_font/resources/private/font_storage.sats"
staload "data_font/resources/private/font_scan.sats"
staload "data_font/atlas/private/font_atlas.sats"
staload "data_font/raster/private/font_math.sats"
staload "data_font/atlas/private/font_cache.sats"
staload "data_font/raster/private/font_outline_compound.sats"
staload "data_font/resources/private/font_metrics.sats"
staload "data_font/raster/private/font_raster.sats"

fun ttf_rasterize(f: !Font, sc: double, minx: int, maxy: int, sw: int, sh: int): void = let
  val () = contours(f, 0, font_get_contour_count(f), minx, maxy, sc)
  val () = zero_cov(f)
in
  scan_rows(f, sw, sh, 0)
end

fun ttf_upload_glyph(f: !Font, r: !Rend, sw: int, sh: int, x0: &int >> _, y0: &int >> _): void = let
  val bw = sw / 2
  val bh = sh / 2
  val () = reserve(f, r, bw, bh, x0, y0)
  val () = blit(f, x0, y0, sw, bw, bh, 0)
in
  upload(f, r, x0, y0, bw, bh)
end

fun ttf_glyph_bitmap(f: !Font, r: !Rend, sc1: double, ax: int, npts: int, g: &gmet >> _): void = let
  var minx: int = pt_x(f, 0)
  var miny: int = pt_y(f, 0)
  var maxx: int = minx
  var maxy: int = miny
  val () = bbox(f, 1, npts, minx, miny, maxx, maxy)
  val sc = sc1 * 2.0
  val sw = clamp_even(iround(n_i2d(maxx - minx) * sc) + 4)
  val sh = clamp_even(iround(n_i2d(maxy - miny) * sc) + 4)
  val () = ttf_rasterize(f, sc, minx, maxy, sw, sh)
  var x0: int = 0
  var y0: int = 0
  val () = ttf_upload_glyph(f, r, sw, sh, x0, y0)
  val top = iround(n_i2d(maxy) * sc1)
  val bx = iround(n_i2d(minx) * sc1)
in
  fill_g(g, ax, bx, top, sw / 2, sh / 2, x0, y0)
end

implement raster_ttf(f, r, gid, g) = let
  val () = load_ttf_outline(f, gid)
  val adv = hmtx_adv(f, gid)
  val sc1 = scale_of(f)
  val ax = iround(n_i2d(adv) * sc1)
  val npts = font_get_point_count(f)
in
  if npts <= 0 then fill_g(g, ax, 0, 0, 0, 0, 0, 0)
  else ttf_glyph_bitmap(f, r, sc1, ax, npts, g)
end
