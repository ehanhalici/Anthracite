#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_types.sats"
staload "data_font/glyph/pass/glyph_pass_sequence.sats"
fun illegal(b: !Buf,t: !OtSequenceLookup(2),m: !GlyphMetadata,r: GlyphRun(2)): GlyphPassResult(1) =
  glyph_pass_multiple(b,t,m,r,@{kind=GlyphAll(),mask=0u})
