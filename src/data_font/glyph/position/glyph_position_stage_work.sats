staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/position_lookup/ot_position_graph_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/pass/glyph_pass_window_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_lookup_workspace_types.sats"
staload "data_font/glyph/position/glyph_position_stage_types.sats"
fun glyph_position_stage_check(stage: !GlyphPositionStage,metadata: !GlyphMetadata,meta: GlyphRunMeta): GlyphPositionStatus
fun glyph_position_stage_walk{n,k:nat}(b: !Buf,stage: !GlyphPositionStage,metadata: !GlyphMetadata,
  s: !GlyphStorage(n),meta: GlyphRunMeta,scale: GlyphScale,d: GlyphPositionDirection,w: !GlyphContextWindow,
  workspace: !GlyphPositionLookupWorkspace(k),remaining: &int >> int,applied: &int >> int,matches: &int >> int): GlyphPositionStatus
