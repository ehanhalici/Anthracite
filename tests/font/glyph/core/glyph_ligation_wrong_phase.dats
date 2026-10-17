#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/opentype/ligation_lookup/ot_ligation_lookup_types.sats"
staload "data_font/glyph/pass/glyph_pass_ligation.sats"
fun illegal(b: !Buf,t: !OtLigationLookup,m: !GlyphMetadata,r: GlyphRun(2)): GlyphPassResult(1) =
  glyph_pass_ligation(b,t,m,r,@{kind=GlyphAll(),mask=0u})
