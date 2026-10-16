staload "mem.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/bidi/bidi_bracket_data.sats"
datavtype BidiClassFixture = BidiClassFixture of (ScalarText, BidiWork)
typedef BidiExpect = @{level_start=int, level_end=int, order_start=int, order_end=int}
fun bidi_class_fixture(source: !Buf, start: int, finish: int): BidiClassFixture
fun bidi_class_test(source: !Buf, start: int, finish: int, brackets: !BidiBrackets, direction: ParagraphDirection, expected: BidiExpect): int
