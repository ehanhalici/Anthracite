#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/ot_substitution_graph_types.sats"
staload "data_font/glyph_substitution_lookup_types.sats"
staload "data_font/glyph_substitution_engine.sats"
fun illegal(b: !Buf,g: !OtSubstitutionGraph,m: !GlyphMetadata,run: GlyphRun(0)): GlyphPassResult(1) =
  glyph_substitution_lookup(b,g,m,run,0,@{selection= @{kind=GlyphAll(),mask=0u},alternate=1})
