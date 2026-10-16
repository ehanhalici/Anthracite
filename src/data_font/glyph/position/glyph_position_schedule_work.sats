staload "mem.sats"
staload "data_font/opentype/position_lookup/ot_position_graph_types.sats"
staload "data_font/opentype/shape/ot_shape_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_stage_types.sats"
staload "data_font/glyph/pass/glyph_pass_window_types.sats"
staload "data_font/glyph/position/glyph_position_lookup_workspace_types.sats"
staload "data_font/glyph/position/glyph_position_lookup_graph_types.sats"
fun glyph_position_schedule_check(g: !OtPositionGraph,s: !OtShapeSchedule(2),m: !GlyphMetadata,meta: GlyphRunMeta): GlyphPositionStatus
fun glyph_position_schedule_walk{n,k:nat}(b: !Buf,g: !OtPositionGraph,schedule: !OtShapeSchedule(2),m: !GlyphMetadata,
  s: !GlyphStorage(n),meta: GlyphRunMeta,scale: GlyphScale,d: GlyphPositionDirection,w: !GlyphContextWindow,
  workspace: !GlyphPositionLookupWorkspace(k),remaining: &int >> int,applied: &int >> int,matches: &int >> int): GlyphPositionStatus
fun glyph_position_schedule_execute(b: !Buf,g: !OtPositionGraph,s: !OtShapeSchedule(2),m: !GlyphMetadata,
  p: GlyphPositioned(0),d: GlyphPositionDirection,w: !GlyphContextWindow,
  capacity: GlyphPositionLookupGraphCapacity): GlyphPositionStageResult
