staload "mem.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup_types.sats"
staload "font/opentype/substitution/gsub_single_contracts.sats"
fun pass_test_run(count: int): GlyphRun(1)
fun pass_test_take(result: GlyphPassResult(1),visited: int,matches: int,errors: &int >> _): GlyphRun(1)
fun pass_test_basic(): int
fun pass_test_sparse(): int
fun pass_test_stress(): int
fun pass_test_font(path: string,font: SingleTestFont): int
fun pass_font_run(b: !Buf,t: !GsubSingle,glyphs: int,input: int,output: int): int
fun pass_font_lookup(b: !Buf,t: !OtSingleLookup,metadata: !GlyphMetadata,glyphs: int,input: int,output: int): int
fun pass_test_cached(): int
fun pass_test_cache_stress(): int
fun pass_test_large_lookup(): Buf
