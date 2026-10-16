#include "data_font/glyph/position/glyph_position_lookup_graph_internal.hats"
staload "data_font/glyph/position/glyph_position_stage_types.sats"
staload "data_font/glyph/position/glyph_position_stage_work.sats"
implement glyph_position_stage_check(stage,m,meta) = let val+ GlyphPositionStage(g,ids,selection,count)=stage
in glyph_position_lookup_graph_validate(g,m,meta) end
