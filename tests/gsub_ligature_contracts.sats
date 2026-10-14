staload "mem.sats"
staload "data_font/opentype_types.sats"
fun ligature_fixture(): Buf
fun ligature_test_priority(): int
fun ligature_test_errors(): int
fun ligature_test_stress(): int
datatype LigatureTestFont = LigatureLatin | LigatureArabic
fun ligature_test_font(path: string,font: LigatureTestFont): int
