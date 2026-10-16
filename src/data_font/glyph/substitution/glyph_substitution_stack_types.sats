staload "data_font/glyph/substitution/glyph_substitution_lookup_types.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/glyph/context/glyph_context_arena_types.sats"
datatype GlyphSubstitutionFrameState = SubstitutionEnter | SubstitutionActions
typedef GlyphSubstitutionFrame = @{state=GlyphSubstitutionFrameState,lookup=int,node=int,action=int,next=int,
  generation=int,matched=bool,context=OtContextMatch(1),chain=GlyphContextChain}
datavtype GlyphSubstitutionStack = {n:nat}{l:addr} GlyphSubstitutionStack of
  (arrayptr(GlyphSubstitutionFrame,l,n),int(n),int)
