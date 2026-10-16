staload "mem.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/opentype/reverse_lookup/ot_reverse_lookup_types.sats"
(* Lookup 8 visits the logical tail first, independently of paragraph direction.
   The original core column is restored on any typed execution failure. *)
fun glyph_pass_reverse(b: !Buf,t: !OtReverseLookup,m: !GlyphMetadata,run: GlyphRun(1),
  selection: GlyphSelection): GlyphPassResult(1)
fun glyph_pass_reverse_budget(b: !Buf,t: !OtReverseLookup,m: !GlyphMetadata,run: GlyphRun(1),
  selection: GlyphSelection,remaining: &int >> int): GlyphPassResult(1)
