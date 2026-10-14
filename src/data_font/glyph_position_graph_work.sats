staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_graph_types.sats"
fun glyph_position_graph_parent(mode: GlyphPositionGraphMode,position: GlyphPosition): int
fun glyph_position_graph_change{n:nat}(graph: !GlyphPositionGraph(n),mode: GlyphPositionGraphMode,
  node: int,position: GlyphPosition,parent: GlyphPosition): GlyphPositionChange
fun glyph_position_graph_chain{n,m,k:nat}(storage: !GlyphStorage(n),meta: GlyphRunMeta,
  cache: !GlyphPositionCache(m),graph: !GlyphPositionGraph(k),mode: GlyphPositionGraphMode,node: int): GlyphPositionStatus
