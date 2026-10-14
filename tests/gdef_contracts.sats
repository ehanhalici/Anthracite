fun gdef_test_metadata(): int
fun gdef_test_marks(): int
fun gdef_test_flags(): int
staload "data_font/gdef_types.sats"
fun gdef_test_font(path: string,base: int,mark: int,expected: GdefGlyphKind): int
