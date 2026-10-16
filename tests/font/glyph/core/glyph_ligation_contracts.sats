staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/opentype/substitution/gsub_ligature_types.sats"
fun ligation_test_metadata_bytes(): Buf
fun ligation_test_flags(code: int): OtLookupFlags
fun ligation_test_metadata(b: !Buf): GlyphMetadata
fun ligation_test_table(first: int,second: int,output: int): Buf
fun ligation_test_parse(b: !Buf): GsubLigatures
fun ligation_test_run(s: string,errors: &int >> _): GlyphRun(1)
fun ligation_test_applied(run: GlyphRun(1),b: !Buf,metadata: !GlyphMetadata,flags: int,errors: &int >> _): GlyphRun(1)
fun ligation_test_basic(): int
fun ligation_test_associations(): int
fun ligation_test_masks(): int
fun ligation_test_cache(): int
fun ligation_test_fonts(latin: string,arabic: string): int
