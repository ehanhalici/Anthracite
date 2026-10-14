staload "mem.sats"
datatype FixtureMap = Fixture4 | Fixture12
fun fixture_put16(b: !Buf, at: int, value: int): void
fun fixture_put32(b: !Buf, at: int, value: int): void
fun fixture_font(map: FixtureMap): Buf
fun fixture_outline_font(): Buf
