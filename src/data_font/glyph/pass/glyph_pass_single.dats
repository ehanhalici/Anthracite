#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/glyph/pass/glyph_pass_work.sats"
staload "data_font/glyph/pass/glyph_pass_single.sats"
implement glyph_pass_single(b,t,run,selection) = let
  val+ GsubSingle(info)=t
  val+ ~GlyphRun(phase,meta,s)=run
in if ine(info.glyphs,meta.glyphs) then
  GlyphPassResult(GlyphRun(phase,meta,s),GlyphPassDomain(),0,0) else let
    val matches=glyph_pass_single_walk(b,t,s,meta,selection)
  in GlyphPassResult(GlyphRun(phase,meta,s),GlyphPassApplied(),meta.live,matches) end end
