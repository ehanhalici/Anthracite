staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_pair_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
fun glyph_position_pair(b: !Buf,table: !GposPairs,metadata: !GlyphMetadata,
  positioned: GlyphPositioned(0),flags: OtLookupFlags,set: int,selection: GlyphSelection): GlyphPositionResult
