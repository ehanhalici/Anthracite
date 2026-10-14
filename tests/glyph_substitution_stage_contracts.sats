staload "mem.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_substitution_stage_types.sats"
fun substitution_stage_fixture(last: string): Buf
fun substitution_stage_build(b: !Buf,m: !GlyphMetadata,features: string): GlyphSubstitutionStage
fun substitution_stage_cases(): int
