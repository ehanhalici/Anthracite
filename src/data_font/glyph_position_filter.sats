staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_position_types.sats"
fun glyph_position_filter_check(metadata: !GlyphMetadata,meta: GlyphRunMeta,glyphs: int,
  flags: OtLookupFlags,set: int): GlyphPositionStatus
fun glyph_position_eligible(b: !Buf,metadata: !GlyphMetadata,flags: OtLookupFlags,set: int,
  selection: GlyphSelection,core: GlyphCore): bool
