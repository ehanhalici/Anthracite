#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "flag.sats"
staload "data_font/font.sats"
staload "data_font/font_glyph_id.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position.sats"
staload "data_font/font_run.sats"
staload "data_font/private/font_storage.sats"
staload "data_font/private/font_run_work.sats"
fun primary(f: !Font,meta: GlyphRunMeta,scale: GlyphScale): FontRunStatus =
  if is_off(font_has_ttf(f)) orelse ine(meta.glyphs,f_get_nglyph(f)) orelse ine(scale.units,f_get_units(f))
  then FontRunFace() else FontRunReady()
fun fallback(f: !Font,meta: GlyphRunMeta,scale: GlyphScale): FontRunStatus =
  if not(font_has_fb(f)) orelse ine(meta.glyphs,f_get_fb_nglyph(f)) orelse ine(scale.units,f_get_fb_units(f))
  then FontRunFace() else FontRunReady()
implement font_run_binding_check(f,p,binding) = let val meta=glyph_position_meta(p) and scale=glyph_position_scale(p)
in if ine(meta.font,binding.font) then FontRunFace()
  else if ine(scale.yPpem,f_get_px(f)) then FontRunScale()
  else case+ binding.face of | GlyphPrimaryFace() => primary(f,meta,scale) | GlyphFallbackFace() => fallback(f,meta,scale) end
