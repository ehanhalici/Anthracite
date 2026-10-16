staload "data_text/bidi/bidi_types.sats"
fun bidi_is_nsm(kind: BidiClass): bool
fun bidi_is_arabic(kind: BidiClass): bool
fun bidi_is_en(kind: BidiClass): bool
fun bidi_is_an(kind: BidiClass): bool
fun bidi_is_et(kind: BidiClass): bool
fun bidi_is_separator(kind: BidiClass): bool
fun bidi_is_cs(kind: BidiClass): bool
fun bidi_is_neutral(kind: BidiClass): bool
fun bidi_is_other(kind: BidiClass): bool
fun bidi_is_line_separator(kind: BidiClass): bool
fun bidi_is_paragraph_separator(kind: BidiClass): bool
fun bidi_is_line_space(kind: BidiClass): bool
fun bidi_level_direction(level: int): BidiClass
fun bidi_numeric_direction(kind: BidiClass): BidiClass
