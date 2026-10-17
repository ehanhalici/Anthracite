staload "mem.sats"
staload "data_font/opentype/substitution/gsub_sequence_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_types.sats"
staload "data_font/glyph/core/glyph_expansion_types.sats"
fun glyph_expansion_make{n:nat}(count: int(n)): GlyphExpansionPlan(n,0)
fun glyph_expansion_append{n,i:nat | i < n}(plan: GlyphExpansionPlan(n,i),entry: GlyphExpansion): GlyphExpansionPlan(n,i+1)
fun glyph_expansion_get{n:nat}(plan: !GlyphExpansionPlan(n,n),index: int): GlyphExpansion
fun glyph_expansion_dispose{n,i:nat}(plan: GlyphExpansionPlan(n,i)): void
fun glyph_expansion_replace{n:nat}(storage: !GlyphStorage(n),meta: GlyphRunMeta,node: int,
  b: !Buf,view: GsubSequenceView): GlyphRunMeta
fun glyph_expansion_read{n:nat}(b: !Buf,t: !OtSequenceLookup(2),m: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,selection: GlyphSelection): GlyphExpansionRead
fun glyph_expansion_commit{n,p:nat}(b: !Buf,plan: !GlyphExpansionPlan(p,p),s: !GlyphStorage(n),meta: GlyphRunMeta): GlyphRunMeta
fun glyph_expansion_execute{n:nat}(b: !Buf,plan: GlyphExpansionPlan(n,n),run: GlyphRun(1)): GlyphPassResult(1)
