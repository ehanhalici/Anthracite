staload "mem.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/opentype/ligation_lookup/ot_ligation_lookup_types.sats"
fun glyph_pass_ligation(b: !Buf,t: !OtLigationLookup,m: !GlyphMetadata,run: GlyphRun(1),selection: GlyphSelection): GlyphPassResult(1)
