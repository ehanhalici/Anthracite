#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "flag.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"
staload "data_font/font_glyph_id.sats"
staload "data_font/private/font_storage.sats"
staload "data_font/private/font_cache_types.sats"
staload "data_font/private/font_cache.sats"
staload "data_font/private/font_raster.sats"
fun reset(g: &gmet >> _): void = g := @{ax=0,bx=0,top=0,bw=0,bh=0,x0=0,y0=0,ok=Off()}
fun fresh(f: !Font,r: !Rend,key: FontCacheKey,g: &gmet >> _): void = let
  val ()=raster_ttf(f,r,key.value,g)
in cache_put_key(f,key,g) end
fun primary(f: !Font,r: !Rend,glyph: int,g: &gmet >> _): FontGlyphStatus =
  if ilt(glyph,0) orelse ige(glyph,f_get_nglyph(f)) then GlyphRasterDomain() else let
    val key: FontCacheKey= @{kind=CachePrimaryGlyph(),value=glyph,ppem=f_get_px(f)}
    val ()=if cache_get_key(f,key,g) = 1 then () else fresh(f,r,key,g)
  in GlyphRasterReady() end
fun fallback(f: !Font,r: !Rend,glyph: int,g: &gmet >> _): FontGlyphStatus =
  if not(font_has_fb(f)) then GlyphRasterUnavailable()
  else if ilt(glyph,0) orelse ige(glyph,f_get_fb_nglyph(f)) then GlyphRasterDomain() else let
    val key: FontCacheKey= @{kind=CacheFallbackGlyph(),value=glyph,ppem=f_get_px(f)}
    val ()=if cache_get_key(f,key,g) = 1 then () else let
      val ()=swap_fb(f)
      val ()=fresh(f,r,key,g)
    in swap_fb(f) end
  in GlyphRasterReady() end
implement font_glyph_id(f,r,face,glyph,g) = let val ()=reset(g) in case+ face of
  | GlyphPrimaryFace() => if is_off(font_has_ttf(f)) then GlyphRasterUnavailable()
    else primary(f,r,glyph,g)
  | GlyphFallbackFace() => fallback(f,r,glyph,g) end
