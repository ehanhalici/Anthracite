staload "mem.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_substitution_lookup_types.sats"
staload "data_font/glyph_substitution_stage_types.sats"
(* Script stages own ordered plan IDs and one uniform glyph selection.
   Different feature masks belong to separate stages. One scratch run and
   reusable workspace cover every lookup; any late failure rolls all back. *)
fun glyph_substitution_stage_parse(b: !Buf,table: !OtLayoutTable(1,0),plan: !OtStagePlan(1),
  metadata: !GlyphMetadata,options: GlyphSubstitutionOptions): GlyphSubstitutionStageRead
fun glyph_substitution_stage_apply(b: !Buf,stage: !GlyphSubstitutionStage,metadata: !GlyphMetadata,
  run: GlyphRun(1)): GlyphSubstitutionStageResult
fun glyph_substitution_stage_budget(b: !Buf,stage: !GlyphSubstitutionStage,metadata: !GlyphMetadata,
  run: GlyphRun(1),remaining: &int >> int): GlyphSubstitutionStageResult
fun glyph_substitution_stage_dispose(stage: GlyphSubstitutionStage): void
