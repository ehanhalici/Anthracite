staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/glyph/context/glyph_context_arena_types.sats"
datatype GlyphSubstitutionStepKind = SubstitutionDone | SubstitutionNested
typedef GlyphSubstitutionStep = @{kind=GlyphSubstitutionStepKind,status=GlyphPassStatus,next=int,matched=bool,
  context=OtContextMatch(1),chain=GlyphContextChain,insertion=GlyphContextInsertion}
typedef GlyphSubstitutionOptions = @{selection=GlyphSelection,alternate=int}
