staload "data_font/opentype/substitution/gsub_sequence_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
typedef GlyphExpansion = @{node=int,view=GsubSequenceView}
datavtype GlyphExpansionPlan(int,int) = {n:nat}{i:nat | i <= n}{l:addr} GlyphExpansionPlan(n,i) of
  (arrayptr(GlyphExpansion,l,n),int(n),int(i),int,int)
datavtype GlyphExpansionRead = {n:nat} ExpansionAccepted of GlyphExpansionPlan(n,n)
  | ExpansionRejected of GlyphPassStatus
