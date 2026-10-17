staload "mem.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/opentype/substitution_graph/ot_substitution_graph_types.sats"
staload "data_font/glyph/substitution/glyph_substitution_lookup_types.sats"
staload "data_font/glyph/substitution/glyph_substitution_engine_types.sats"
staload "data_font/glyph/context/glyph_context_arena_types.sats"
fun glyph_substitution_enter(b: !Buf,g: !OtSubstitutionGraph,m: !GlyphMetadata,run: &GlyphRun(1) >> GlyphRun(1),
  options: GlyphSubstitutionOptions,w: &GlyphSubstitutionWorkspace >> GlyphSubstitutionWorkspace,depth: int,
  generation: &int >> int,remaining: &int >> int): GlyphSubstitutionEvent
fun glyph_substitution_actions(b: !Buf,run: !GlyphRun(1),w: &GlyphSubstitutionWorkspace >> GlyphSubstitutionWorkspace,
  depth: int,generation: int,remaining: &int >> int): GlyphSubstitutionEvent
fun glyph_substitution_next(run: !GlyphRun(1),node: int,remaining: &int >> int): GlyphContextNode
fun glyph_substitution_ready(status: GlyphPassStatus): bool
fun glyph_substitution_validate_graph(g: !OtSubstitutionGraph,m: !GlyphMetadata,run: !GlyphRun(1)): GlyphPassStatus
fun glyph_substitution_validate(g: !OtSubstitutionGraph,m: !GlyphMetadata,run: !GlyphRun(1),lookup: int): GlyphPassStatus
fun glyph_substitution_traversal(g: !OtSubstitutionGraph,lookup: int): GlyphSubstitutionTraversal
fun glyph_substitution_capacity(run: !GlyphRun(1),limits: OtContextLimits): GlyphSubstitutionCapacity
fun glyph_substitution_workspace_make(limits: OtContextLimits,capacity: GlyphSubstitutionCapacity): GlyphSubstitutionWorkspaceRead
fun glyph_substitution_workspace_dispose(w: GlyphSubstitutionWorkspace): void
fun glyph_substitution_event_fault(status: GlyphPassStatus): GlyphSubstitutionEvent
fun glyph_substitution_event_continue(depth: int): GlyphSubstitutionEvent
fun glyph_substitution_event_done(depth: int,next: int,matched: bool): GlyphSubstitutionEvent
fun glyph_substitution_transition(b: !Buf,g: !OtSubstitutionGraph,m: !GlyphMetadata,
  run: &GlyphRun(1) >> GlyphRun(1),options: GlyphSubstitutionOptions,w: &GlyphSubstitutionWorkspace >> GlyphSubstitutionWorkspace,
  depth: int,generation: &int >> int,remaining: &int >> int): GlyphSubstitutionEvent
fun glyph_substitution_nested(b: !Buf,g: !OtSubstitutionGraph,m: !GlyphMetadata,
  run: &GlyphRun(1) >> GlyphRun(1),lookup: int,node: int,options: GlyphSubstitutionOptions,
  w: &GlyphSubstitutionWorkspace >> GlyphSubstitutionWorkspace,generation: &int >> int,
  remaining: &int >> int): GlyphSubstitutionEvent
fun glyph_substitution_walk(b: !Buf,g: !OtSubstitutionGraph,m: !GlyphMetadata,run: &GlyphRun(1) >> GlyphRun(1),
  lookup: int,options: GlyphSubstitutionOptions,w: &GlyphSubstitutionWorkspace >> GlyphSubstitutionWorkspace,
  remaining: &int >> int): GlyphSubstitutionCounts
