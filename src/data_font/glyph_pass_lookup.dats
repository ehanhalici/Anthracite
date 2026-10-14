#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/ot_single_lookup_types.sats"
staload "data_font/glyph_pass_lookup_work.sats"
staload "data_font/glyph_pass_lookup.sats"
implement glyph_pass_lookup(b,t,m,run,selection) = let
  val+ ~GlyphRun(phase,meta,s)=run
  val status=glyph_pass_lookup_check(t,m,meta)
in case+ status of
  | GlyphPassApplied() => let val matches=glyph_pass_lookup_walk(b,t,m,s,meta,selection) in
    GlyphPassResult(GlyphRun(phase,meta,s),status,meta.live,matches) end
  | GlyphPassDomain() => GlyphPassResult(GlyphRun(phase,meta,s),status,0,0)
  | GlyphPassReference() => GlyphPassResult(GlyphRun(phase,meta,s),status,0,0)
  | GlyphPassCapacity() => GlyphPassResult(GlyphRun(phase,meta,s),status,0,0) end
