staload "mem.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_stage_types.sats"
(* Uniform glyph eligibility across this selected stage. The caller's plan
   already preserves ordered, deduplicated lookup IDs and required features.
   Script-specific stages with different masks are separate stage owners.
   Parse once per immutable font/plan; execute without reparsing or copying
   font bytes. One scratch position column makes the entire stage atomic. *)
fun glyph_position_stage_parse(b: !Buf,table: !OtLayoutTable(2,0),plan: !OtStagePlan(2),metadata: !GlyphMetadata,
  selection: GlyphSelection): GlyphPositionStageRead
fun glyph_position_stage_apply(b: !Buf,stage: !GlyphPositionStage,metadata: !GlyphMetadata,
  positioned: GlyphPositioned(0),direction: GlyphPositionDirection): GlyphPositionStageResult
fun glyph_position_stage_dispose(stage: GlyphPositionStage): void
