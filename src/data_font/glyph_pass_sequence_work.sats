staload "mem.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/ot_sequence_lookup_types.sats"
fun glyph_pass_sequence_check{kind:int}(lookup: !OtSequenceLookup(kind),metadata: !GlyphMetadata,
  meta: GlyphRunMeta): GlyphPassStatus
fun glyph_pass_sequence_eligible(b: !Buf,m: !GlyphMetadata,h: OtLookupInfo(1),
  selection: GlyphSelection,core: GlyphCore): bool
fun glyph_pass_alternate_walk{n:nat}(b: !Buf,t: !OtSequenceLookup(3),m: !GlyphMetadata,
  s: !GlyphStorage(n),meta: GlyphRunMeta,selection: GlyphSelection,choice: int): int
