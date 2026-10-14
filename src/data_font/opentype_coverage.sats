staload "mem.sats"
staload "data_font/opentype_types.sats"
fun ot_coverage_parse(b: !Buf,span: OtSpan,glyphs: int): OtCoverageRead
fun ot_coverage_index(b: !Buf,coverage: OtCoverageInfo,glyph: int): OtIndex
