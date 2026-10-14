staload "mem.sats"
staload "data_font/opentype_types.sats"
fun ot_fixture_words(words: string): Buf
fun ot_fixture_span(b: !Buf): OtSpan
fun ot_fixture_put16(b: !Buf,relative: int,value: int): void
fun ot_fixture_read16(b: !Buf,relative: int): int
fun ot_fixture_reject_coverage(b: !Buf,span: OtSpan,glyphs: int): int
fun ot_fixture_reject_class(b: !Buf,span: OtSpan,glyphs: int): int
fun ot_fixture_reject_device(b: !Buf,span: OtSpan): int
