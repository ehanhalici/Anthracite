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



(* Character-to-raster dispatch. *)
staload "data_font/private/font_storage.sats"
staload "data_font/private/font_raster.sats"
staload "data_font/private/font_bitmap.sats"
staload "data_font/private/font_cache.sats"

fun raster_fallback(f: !Font, r: !Rend, cp: int, g: &gmet >> _): bool =
  if not(font_has_fb(f)) then false
  else let
    val () = swap_fb(f)
    val gid = cmap_gid(f, cp)
  in
    if igt(gid, 0) then let
      val () = raster_ttf(f, r, gid, g)
      val () = swap_fb(f)
    in
      true
    end else let
      val () = swap_fb(f)
    in
      false
    end
  end

fun raster(f: !Font, r: !Rend, cp: int, g: &gmet >> _): void =
  if is_off(font_has_ttf(f)) then raster_bitmap(f, r, cp, g)
  else let
    val gid = cmap_gid(f, cp)
  in
    if gid <= 0 then
      if raster_fallback(f, r, cp, g) then ()
      else if cp = CHAR_SPACE orelse cp = CHAR_TAB then fill_g(g, idiv(f_get_px(f), 2), 0, font_asc(f), 0, 0, 0, 0)
      else raster_bitmap(f, r, cp, g)
    else raster_ttf(f, r, gid, g)
  end

implement font_glyph(f, r, cp, g) =
  if cache_get(f, cp, g) = 1 then ()
  else let
    val () = raster(f, r, cp, g)
  in
    cache_put(f, cp, g)
  end
