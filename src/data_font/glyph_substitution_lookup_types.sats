staload "data_font/glyph_pass_types.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/glyph_context_arena_types.sats"
datatype GlyphSubstitutionStepKind = SubstitutionDone | SubstitutionNested
typedef GlyphSubstitutionStep = @{kind=GlyphSubstitutionStepKind,status=GlyphPassStatus,next=int,matched=bool,
  context=OtContextMatch(1),chain=GlyphContextChain,insertion=GlyphContextInsertion}
typedef GlyphSubstitutionOptions = @{selection=GlyphSelection,alternate=int}
