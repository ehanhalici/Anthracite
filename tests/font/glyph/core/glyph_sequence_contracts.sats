staload "mem.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/opentype/substitution/gsub_sequence_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_types.sats"
fun seq_test_fixture(): Buf
fun seq_test_metadata(b: !Buf,font: int,glyphs: int): GlyphMetadata
fun seq_test_table{kind:int}(b: !Buf,domain: GsubSequenceDomain(kind)): OtSequenceLookup(kind)
fun seq_test_nominal(glyphs: int,input: int,count: int,errors: &int >> _): GlyphRun(1)
fun seq_test_core(run: !GlyphRun(1),node: int,glyph: int,source: int): int
fun seq_test_core_cluster(run: !GlyphRun(1),node: int,glyph: int,source: int,cluster: int): int
fun seq_test_list(run: !GlyphRun(1),expected: string): int
fun seq_test_cache(): int
fun seq_test_multiple(): int
fun seq_test_alternate(): int
fun seq_test_filters(): int
fun seq_test_rejections(): int
fun seq_test_stress(): int
fun seq_test_fonts(path: string): int
fun seq_font_multiple(b: !Buf,t: !OtSequenceLookup(2),m: !GlyphMetadata,glyphs: int,
  input: int,oracle: !Buf,at: int,count: int): int
fun seq_font_alternate(b: !Buf,t: !OtSequenceLookup(3),m: !GlyphMetadata,glyphs: int,
  input: int,oracle: !Buf,at: int,count: int): int
