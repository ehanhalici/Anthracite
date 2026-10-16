staload "mem.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/substitution_graph/ot_substitution_graph_types.sats"
staload "data_font/glyph/pass/glyph_pass_window_types.sats"
staload "data_font/glyph/context/glyph_context_arena_types.sats"
staload "data_font/glyph/substitution/glyph_substitution_lookup_types.sats"
fun glyph_substitution_done(status: GlyphPassStatus,next: int,matched: bool,insertion: GlyphContextInsertion): GlyphSubstitutionStep
fun glyph_substitution_unchanged(next: int): GlyphSubstitutionStep
fun glyph_substitution_fault(status: GlyphPassStatus): GlyphSubstitutionStep
fun glyph_substitution_edit_status(status: GlyphEditStatus): GlyphPassStatus
fun glyph_substitution_entry_header(entry: !OtSubstitutionGraphEntry): OtLookupInfo(1)
fun glyph_substitution_scalar(b: !Buf,entry: !OtSubstitutionGraphEntry,run: !GlyphRun(1),
  options: GlyphSubstitutionOptions,node: int): GlyphSubstitutionStep
fun glyph_substitution_multiple(b: !Buf,entry: !OtSubstitutionGraphEntry,run: &GlyphRun(1) >> GlyphRun(1),
  node: int,output: &Buf >> Buf,maximum: int,remaining: &int >> int): GlyphSubstitutionStep
fun glyph_substitution_ligature(b: !Buf,entry: !OtSubstitutionGraphEntry,m: !GlyphMetadata,run: &GlyphRun(1) >> GlyphRun(1),
  options: GlyphSubstitutionOptions,node: int,glyphs: !Buf,nodes: !Buf,weights: !Buf,remaining: &int >> int): GlyphSubstitutionStep
fun glyph_substitution_reverse(b: !Buf,entry: !OtSubstitutionGraphEntry,m: !GlyphMetadata,run: !GlyphRun(1),
  options: GlyphSubstitutionOptions,node: int,w: !GlyphContextWindow,remaining: &int >> int): GlyphSubstitutionStep
fun glyph_substitution_context(b: !Buf,entry: !OtSubstitutionGraphEntry,m: !GlyphMetadata,run: !GlyphRun(1),
  options: GlyphSubstitutionOptions,node: int,w: !GlyphContextWindow,arena: &GlyphContextArena >> GlyphContextArena,
  remaining: &int >> int): GlyphSubstitutionStep
fun glyph_substitution_step(b: !Buf,g: !OtSubstitutionGraph,m: !GlyphMetadata,run: &GlyphRun(1) >> GlyphRun(1),
  options: GlyphSubstitutionOptions,lookup: int,node: int,w: !GlyphContextWindow,
  arena: &GlyphContextArena >> GlyphContextArena,output: &Buf >> Buf,glyphs: !Buf,nodes: !Buf,weights: !Buf,maximum: int,
  remaining: &int >> int): GlyphSubstitutionStep
