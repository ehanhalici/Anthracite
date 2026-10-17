staload "mem.sats"
staload "data_font/opentype/substitution_graph/ot_substitution_graph_types.sats"
staload "data_font/opentype/shape/ot_shape_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/substitution/glyph_substitution_stage_types.sats"
(* One scratch run and one workspace cover the entire script schedule.
   The font-scoped immutable graph is borrowed, never cloned/reparsed. *)
fun glyph_substitution_schedule_apply(b: !Buf,g: !OtSubstitutionGraph,s: !OtShapeSchedule(1),
  metadata: !GlyphMetadata,run: GlyphRun(1)): GlyphSubstitutionStageResult
fun glyph_substitution_schedule_budget(b: !Buf,g: !OtSubstitutionGraph,s: !OtShapeSchedule(1),
  metadata: !GlyphMetadata,run: GlyphRun(1),remaining: &int >> int): GlyphSubstitutionStageResult
