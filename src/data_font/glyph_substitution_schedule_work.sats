staload "mem.sats"
staload "data_font/ot_substitution_graph_types.sats"
staload "data_font/ot_shape_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_substitution_engine_types.sats"
fun glyph_substitution_schedule_check(g: !OtSubstitutionGraph,s: !OtShapeSchedule(1),
  m: !GlyphMetadata,run: !GlyphRun(1)): GlyphPassStatus
fun glyph_substitution_schedule_walk(b: !Buf,g: !OtSubstitutionGraph,s: !OtShapeSchedule(1),m: !GlyphMetadata,
  run: &GlyphRun(1) >> GlyphRun(1),w: &GlyphSubstitutionWorkspace >> GlyphSubstitutionWorkspace,
  remaining: &int >> int): GlyphSubstitutionCounts

