staload "data_font/glyph/run/glyph_run_types.sats"
datatype GlyphTravel = GlyphForward | GlyphBackward
datatype GlyphNeighborStatus = NeighborFound | NeighborEnd | NeighborDomain | NeighborReference | NeighborNode
typedef GlyphNeighbor = @{status=GlyphNeighborStatus,node=int,core=GlyphCore}
