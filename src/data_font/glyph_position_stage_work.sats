staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_position_graph_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_pass_window_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_lookup_workspace_types.sats"
staload "data_font/glyph_position_stage_types.sats"
fun glyph_position_stage_check(stage: !GlyphPositionStage,metadata: !GlyphMetadata,meta: GlyphRunMeta): GlyphPositionStatus
fun glyph_position_stage_walk{n,k:nat}(b: !Buf,stage: !GlyphPositionStage,metadata: !GlyphMetadata,
  s: !GlyphStorage(n),meta: GlyphRunMeta,scale: GlyphScale,d: GlyphPositionDirection,w: !GlyphContextWindow,
  workspace: !GlyphPositionLookupWorkspace(k),remaining: &int >> int,applied: &int >> int,matches: &int >> int): GlyphPositionStatus
