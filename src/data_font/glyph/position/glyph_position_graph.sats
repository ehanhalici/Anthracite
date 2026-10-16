staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_graph_types.sats"
fun glyph_position_graph_make{n:nat}(count: int(n)): GlyphPositionGraph(n)
fun glyph_position_graph_dispose{n:nat}(graph: GlyphPositionGraph(n)): void
fun glyph_position_graph_visit{n:nat}(graph: !GlyphPositionGraph(n),node: int): GlyphPositionVisit
fun glyph_position_graph_set_visit{n:nat}(graph: !GlyphPositionGraph(n),node: int,state: GlyphPositionVisit): void
fun glyph_position_graph_origin{n:nat}(graph: !GlyphPositionGraph(n),node: int): GlyphPositionOrigin
fun glyph_position_graph_set_origin{n:nat}(graph: !GlyphPositionGraph(n),node: int,origin: GlyphPositionOrigin): void
fun glyph_position_graph_push{n:nat}(graph: !GlyphPositionGraph(n),depth: int,node: int): void
fun glyph_position_graph_path{n:nat}(graph: !GlyphPositionGraph(n),depth: int): int
fun glyph_position_graph_prefix{n,m,k:nat}(storage: !GlyphStorage(n),meta: GlyphRunMeta,
  cache: !GlyphPositionCache(m),graph: !GlyphPositionGraph(k),direction: GlyphPositionDirection): GlyphPositionStatus
fun glyph_position_graph_resolve{n,m,k:nat}(storage: !GlyphStorage(n),meta: GlyphRunMeta,
  cache: !GlyphPositionCache(m),graph: !GlyphPositionGraph(k),mode: GlyphPositionGraphMode): GlyphPositionStatus
