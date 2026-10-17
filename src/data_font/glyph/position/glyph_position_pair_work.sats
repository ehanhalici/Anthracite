staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_pair_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
typedef GlyphPairStep = @{status=GlyphPositionStatus,next=int,matched=bool}
fun glyph_position_pair_apply{n,m:nat}(b: !Buf,t: !GposPairs,s: !GlyphStorage(n),scale: GlyphScale,
  cache: !GlyphPositionCache(m),first: int,second: int,core: GlyphCore): GlyphPairStep
fun glyph_position_pair_walk{n,m:nat}(b: !Buf,t: !GposPairs,metadata: !GlyphMetadata,
  s: !GlyphStorage(n),meta: GlyphRunMeta,scale: GlyphScale,flags: OtLookupFlags,set: int,
  selection: GlyphSelection,cache: !GlyphPositionCache(m),matches: &int >> _): GlyphPositionStatus
