staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position_lookup/ot_position_graph_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
datavtype GlyphPositionStage = GlyphPositionStage of (OtPositionGraph,Buf,GlyphSelection,int)
datavtype GlyphPositionStageRead = PositionStageAccepted of GlyphPositionStage | PositionStageRejected of OtError
datavtype GlyphPositionStageResult = PositionStageResult of (GlyphPositioned(0),GlyphPositionStatus,int,int)
