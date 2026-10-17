staload "mem.sats"
staload "data_font/opentype/substitution_graph/ot_substitution_graph_types.sats"
fun substitution_cache_fixture(first: !Buf,second: !Buf,third: !Buf): Buf
fun substitution_cache_parse(b: !Buf): OtSubstitutionGraphRead
fun substitution_cache_contexts(): int
fun substitution_cache_errors(): int
fun substitution_cache_fonts(latin: string,arabic: string): int
