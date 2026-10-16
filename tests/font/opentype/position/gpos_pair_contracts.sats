staload "mem.sats"
datatype PairFixture = GlyphPairs | ClassPairs | ZeroPairs | DevicePairs | AbsentSecond
fun gpos_pair_fixture(which: PairFixture): Buf
fun gpos_pair_test_matches(): int
fun gpos_pair_test_errors(): int
fun gpos_pair_test_stress(): int
fun gpos_pair_test_font(path: string): int
