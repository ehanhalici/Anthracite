#include "data_font/glyph/position/glyph_position_lookup_graph_internal.hats"
staload "data_font/opentype/position_lookup/ot_position_graph.sats"
staload "data_font/glyph/position/glyph_position_stage_types.sats"
staload "data_font/glyph/position/glyph_position_stage.sats"
implement glyph_position_stage_dispose(stage) = let val+ ~GlyphPositionStage(g,ids,selection,count)=stage
in ot_position_graph_dispose(g); buf_free(ids) end
