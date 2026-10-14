staload "mem.sats"
staload "data_font/ot_position_graph_types.sats"
staload "data_font/ot_shape_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_stage_types.sats"
(* Horizontal positioning recipes currently select global features only.
   Unsupported masked schedules are rejected, never treated as global. *)
fun glyph_position_schedule_apply(b: !Buf,g: !OtPositionGraph,s: !OtShapeSchedule(2),
  m: !GlyphMetadata,p: GlyphPositioned(0),direction: GlyphPositionDirection): GlyphPositionStageResult

