#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/glyph_pass_ligature.sats"
fun illegal(b: !Buf,t: !GsubLigatures,m: !GlyphMetadata,r: GlyphRun(0),f: OtLookupFlags): GlyphPassResult(1) =
  glyph_pass_ligature(b,t,m,r,f,0,@{kind=GlyphAll(),mask=0u})
