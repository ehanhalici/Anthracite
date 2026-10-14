staload "mem.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_single_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_position_types.sats"
fun glyph_position_single_walk{n,m:nat}(b: !Buf,table: !GposSingle,metadata: !GlyphMetadata,
  storage: !GlyphStorage(n),meta: GlyphRunMeta,scale: GlyphScale,flags: OtLookupFlags,set: int,
  selection: GlyphSelection,cache: !GlyphPositionCache(m),matches: &int >> _): GlyphPositionStatus
