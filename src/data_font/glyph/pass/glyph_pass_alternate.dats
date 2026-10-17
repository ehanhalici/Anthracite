#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_types.sats"
staload "data_font/glyph/pass/glyph_pass_sequence_work.sats"
staload "data_font/glyph/pass/glyph_pass_sequence.sats"
implement glyph_pass_alternate(b,t,m,run,selection,choice) = let
  val+ ~GlyphRun(phase,meta,s)=run
  val status=glyph_pass_sequence_check(t,m,meta)
in case+ status of
  | GlyphPassApplied() => let val matches=glyph_pass_alternate_walk(b,t,m,s,meta,selection,choice) in
    GlyphPassResult(GlyphRun(phase,meta,s),status,meta.live,matches) end
  | GlyphPassDomain() => GlyphPassResult(GlyphRun(phase,meta,s),status,0,0)
  | GlyphPassReference() => GlyphPassResult(GlyphRun(phase,meta,s),status,0,0)
  | GlyphPassCapacity() => GlyphPassResult(GlyphRun(phase,meta,s),status,0,0) end
