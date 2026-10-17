#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "flag.sats"
staload "data_font/resources/font.sats"
staload "data_font/atlas/font_glyph_id.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/text/run/font_run.sats"
staload "data_font/resources/private/font_storage.sats"
staload "data_font/text/run/private/font_run_work.sats"
fun primary(f: !Font,meta: GlyphRunMeta,scale: GlyphScale): FontRunStatus =
  if is_off(font_has_ttf(f)) orelse ine(meta.glyphs,font_get_glyph_count(f)) orelse ine(scale.units,font_get_units(f))
  then FontRunFace() else FontRunReady()
fun fallback(f: !Font,meta: GlyphRunMeta,scale: GlyphScale): FontRunStatus =
  if not(font_has_fb(f)) orelse ine(meta.glyphs,font_get_fallback_glyph_count(f)) orelse ine(scale.units,font_get_fallback_units(f))
  then FontRunFace() else FontRunReady()
implement font_run_binding_check(f,p,binding) = let val meta=glyph_position_meta(p) and scale=glyph_position_scale(p)
in if ine(meta.font,binding.font) then FontRunFace()
  else if ine(scale.yPpem,font_get_px(f)) then FontRunScale()
  else case+ binding.face of | GlyphPrimaryFace() => primary(f,meta,scale) | GlyphFallbackFace() => fallback(f,meta,scale) end
