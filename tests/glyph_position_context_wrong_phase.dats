#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/ot_position_graph_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_lookup_graph.sats"
fun illegal(b: !Buf,g: !OtPositionGraph,m: !GlyphMetadata,p: GlyphPositioned(1)): GlyphPositionResult =
  glyph_position_lookup_graph_lookup(b,g,m,p,0,@{kind=GlyphAll(),mask=0u},PositionLTR())
