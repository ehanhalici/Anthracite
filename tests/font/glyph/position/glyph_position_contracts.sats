staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
datatype PositionTestClasses = TestBaseClasses | TestMarkClasses
fun position_test_fixture(words: string,classes: PositionTestClasses): Buf
fun position_test_span(b: !Buf): OtSpan
fun position_test_metadata(b: !Buf): GlyphMetadata
fun position_test_run(words: string,errors: &int >> _): GlyphPositioned(0)
fun position_test_set(p: !GlyphPositioned(0),node: int,value: GlyphPosition): void
fun position_test_mask(p: !GlyphPositioned(0),node: int,mask: uint): void
fun position_test_take(result: GlyphPositionResult,visited: int,matches: int,errors: &int >> _): GlyphPositioned(0)
fun position_test_frozen(result: GlyphPositionFinished,errors: &int >> _): GlyphPositioned(1)
fun position_test_values{phase:int}(p: !GlyphPositioned(phase),node: int,xa: int,ya: int,xo: int,yo: int): int
fun position_test_flags(): OtLookupFlags
fun position_test_all(): GlyphSelection
fun position_test_scale_cases(): int
fun position_test_single_cases(): int
fun position_test_pair_cases(): int
fun position_test_cursive_cases(): int
fun position_test_mark_cases(): int
fun position_test_graph_cases(): int
fun position_test_lookup_cases(): int
fun position_test_lookup_pair_cases(): int
fun position_test_lookup_mark_cases(): int
fun position_test_lookup_error_cases(): int
fun position_test_measure_cases(): int
fun position_test_stage_cases(): int
fun position_test_fonts(latin: string,arabic: string,unicode: string,joining: string): int
fun position_test_normalized(latin: string,arabic: string,unicode: string,normalization: string): int
