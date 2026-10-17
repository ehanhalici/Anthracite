staload "mem.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/bidi/bidi_line.sats"
typedef BidiTestFields = @{direction=int, base=int, levels=int, order=int}
fun bidi_fixture_text(source: !Buf, start: int, finish: int): ScalarText
fun bidi_fixture_decimal(source: !Buf, position: &int >> _, finish: int): int
fun bidi_fixture_fields(source: !Buf, start: int, finish: int): BidiTestFields
fun bidi_fixture_check_levels(source: !Buf, start: int, finish: int, work: !BidiWork): int
fun bidi_fixture_check_order(source: !Buf, start: int, finish: int, order: !BidiOrder): int
