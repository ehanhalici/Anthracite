staload "mem.sats"
staload "data_font/ot_position_graph_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_pass_window_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_lookup_graph_types.sats"
staload "data_font/glyph_position_lookup_workspace_types.sats"
fun glyph_position_lookup_workspace_make{n:nat}(used: int(n),lookups: int,capacity: GlyphPositionLookupGraphCapacity): GlyphPositionLookupWorkspace(n)
fun glyph_position_lookup_workspace_dispose{n:nat}(workspace: GlyphPositionLookupWorkspace(n)): void
fun glyph_position_lookup_workspace_prepare{n,k:nat}(b: !Buf,g: !OtPositionGraph,m: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,selection: GlyphSelection,workspace: !GlyphPositionLookupWorkspace(k)): GlyphPositionStatus
fun glyph_position_lookup_workspace_walk{n,k:nat}(b: !Buf,g: !OtPositionGraph,m: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,scale: GlyphScale,selection: GlyphSelection,d: GlyphPositionDirection,lookup: int,w: !GlyphContextWindow,
  workspace: !GlyphPositionLookupWorkspace(k),remaining: &int >> int,matches: &int >> int): GlyphPositionStatus
fun glyph_position_lookup_workspace_commit{n,k:nat}(workspace: !GlyphPositionLookupWorkspace(k),s: !GlyphStorage(n),used: int): void
