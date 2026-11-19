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
staload "data_font/raster/private/font_outline_cff.sats"
staload "data_font/resources/private/font_metrics.sats"
staload "data_font/raster/private/font_raster.sats"

fun ttf_glyph_bitmap(f: !Font, r: !Rend, sc1: double, ax: int, npts: int, g: &gmet >> _): void = let
  var minx: int = pt_x(f, 0)
  var miny: int = pt_y(f, 0)
  var maxx: int = minx
  var maxy: int = miny
  val () = bbox(f, 1, npts, minx, miny, maxx, maxy)
  val bw = imax(2, imin(254, iround(n_i2d(maxx - minx) * sc1) + 2))
  val bh = imax(2, imin(254, iround(n_i2d(maxy - miny) * sc1) + 2))
  val nends = font_get_contour_count(f)
  val () = if font_outline_is_cff(f) then cff_contours(f, 0, nends, minx, maxy, sc1 * 16.0)
           else contours(f, 0, nends, minx, maxy, sc1 * 16.0)
  var x0: int = 0
  var y0: int = 0
  val () = reserve(f, r, bw, bh, x0, y0)
  val () = raster_scan_to_atlas(f, x0, y0, bw, bh)
  val () = upload(f, r, x0, y0, bw, bh)
  val top = iround(n_i2d(maxy) * sc1)
  val bx = iround(n_i2d(minx) * sc1)
in
  fill_g(g, ax, bx, top, bw, bh, x0, y0)
end

implement raster_ttf(f, r, gid, g) = let
  val () = if font_outline_is_cff(f) then load_cff_outline(f, gid) else load_ttf_outline(f, gid)
  val adv = hmtx_adv(f, gid)
  val sc1 = scale_of(f)
  val ax = iround(n_i2d(adv) * sc1)
  val npts = font_get_point_count(f)
in
  if npts <= 0 then fill_g(g, ax, 0, 0, 0, 0, 0, 0)
  else ttf_glyph_bitmap(f, r, sc1, ax, npts, g)
end
