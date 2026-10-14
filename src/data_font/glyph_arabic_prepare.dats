#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "data_text/unicode_property.sats"
staload "data_text/arabic_join_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_arabic_work.sats"
staload "data_font/glyph_arabic.sats"
implement glyph_arabic_prepare(map,plan,context,run) = let
  val+ ~GlyphRun(phase,meta,s)=run
  val ()=glyph_arabic_walk(map,plan,context,s,meta)
in GlyphRun(RunSubstitution(),meta,s) end
