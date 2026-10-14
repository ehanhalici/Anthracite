staload "mem.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/ot_substitution_graph_types.sats"
staload "data_font/glyph_substitution_lookup_types.sats"
(* Whole-lookup transaction: a rejected nested structural mutation never
   publishes a partially substituted run. The font cache is reusable. *)
fun glyph_substitution_lookup(b: !Buf,g: !OtSubstitutionGraph,m: !GlyphMetadata,
  run: GlyphRun(1),lookup: int,options: GlyphSubstitutionOptions): GlyphPassResult(1)
fun glyph_substitution_lookup_budget(b: !Buf,g: !OtSubstitutionGraph,m: !GlyphMetadata,
  run: GlyphRun(1),lookup: int,options: GlyphSubstitutionOptions,remaining: &int >> int): GlyphPassResult(1)
