staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_pair_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_position_types.sats"
fun glyph_position_pair(b: !Buf,table: !GposPairs,metadata: !GlyphMetadata,
  positioned: GlyphPositioned(0),flags: OtLookupFlags,set: int,selection: GlyphSelection): GlyphPositionResult
