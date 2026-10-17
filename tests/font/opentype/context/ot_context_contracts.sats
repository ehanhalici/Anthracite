staload "mem.sats"
staload "data_font/opentype/context/ot_context_types.sats"
datatype ContextFixture = PlainGlyph | PlainClass | PlainCoverage | ChainGlyph | ChainClass | ChainCoverage
fun context_fixture(which: ContextFixture): Buf
fun context_fixture_mode(which: ContextFixture): OtContextMode
fun context_fixture_classes(which: ContextFixture): bool
fun context_test_match(): int
fun context_test_priority(): int
fun context_test_errors(): int
fun context_test_stress(): int
