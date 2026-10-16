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
staload "data_font/glyph/core/glyph_expansion_types.sats"
staload "data_font/glyph/core/glyph_expansion_work.sats"
fun prepare(b: !Buf,t: !OtSequenceLookup(2),m: !GlyphMetadata,run: GlyphRun(1),selection: GlyphSelection): GlyphPassResult(1) = let
  val+ ~GlyphRun(phase,meta,s)=run
in case+ glyph_expansion_read(b,t,m,s,meta,selection) of
  | ~ExpansionRejected(status) => GlyphPassResult(GlyphRun(phase,meta,s),status,0,0)
  | ~ExpansionAccepted(plan) => glyph_expansion_execute(b,plan,GlyphRun(phase,meta,s)) end
implement glyph_pass_multiple(b,t,m,run,selection) = let
  val+ GlyphRun(phase,meta,s)=run
  val status=glyph_pass_sequence_check(t,m,meta)
in case+ status of
  | GlyphPassApplied() => prepare(b,t,m,run,selection)
  | GlyphPassDomain() => GlyphPassResult(run,status,0,0)
  | GlyphPassReference() => GlyphPassResult(run,status,0,0)
  | GlyphPassCapacity() => GlyphPassResult(run,status,0,0) end
