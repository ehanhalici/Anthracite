staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_neighbor_types.sats"
fun glyph_neighbor_empty(status: GlyphNeighborStatus): GlyphNeighbor
fun glyph_neighbor_check(metadata: !GlyphMetadata,meta: GlyphRunMeta,flags: OtLookupFlags,set: int): GlyphNeighborStatus
fun glyph_neighbor_search{n:nat}(b: !Buf,metadata: !GlyphMetadata,storage: !GlyphStorage(n),
  meta: GlyphRunMeta,flags: OtLookupFlags,set: int,node: int,travel: GlyphTravel): GlyphNeighbor
