staload "mem.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/ot_single_lookup_types.sats"
fun lookup_test_fixture(flags: int): Buf
fun lookup_test_metadata(b: !Buf,font: int,glyphs: int): GlyphMetadata
fun lookup_test_table(b: !Buf,glyphs: int): OtSingleLookup
fun lookup_test_glyphs(run: !GlyphRun(1),expected: string): int
fun lookup_test_reject(result: GlyphPassResult(1),expected: GlyphPassStatus,errors: &int >> _): GlyphRun(1)
fun lookup_test_filters(): int
fun lookup_test_properties(): int
fun lookup_test_references(): int
fun lookup_test_capacity(): int
fun lookup_test_neighbors(): int
fun lookup_test_neighbor_sparse(): int
fun lookup_test_neighbor_stress(): int
fun lookup_test_neighbor_rejections(): int
