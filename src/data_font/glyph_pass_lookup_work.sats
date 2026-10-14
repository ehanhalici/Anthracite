staload "mem.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/ot_single_lookup_types.sats"
fun glyph_pass_lookup_check(lookup: !OtSingleLookup,metadata: !GlyphMetadata,meta: GlyphRunMeta): GlyphPassStatus
fun glyph_pass_lookup_walk{n:nat}(b: !Buf,lookup: !OtSingleLookup,metadata: !GlyphMetadata,
  storage: !GlyphStorage(n),meta: GlyphRunMeta,selection: GlyphSelection): int
