staload "data_text/line_break/line_types.sats"
fun line_is_hard(k: LineClass): bool
fun line_is_combining(k: LineClass): bool
fun line_accepts_marks(k: LineClass): bool
fun line_is_letter(k: LineClass): bool
fun line_is_hyphen(k: LineClass): bool
fun line_is_close(k: LineClass): bool
fun line_is_number_sep(k: LineClass): bool
fun line_is_prefix(k: LineClass): bool
fun line_is_ideograph(k: LineClass): bool
fun line_is_hangul(k: LineClass): bool
fun line_is_word_start(k: LineClass): bool
fun line_is_initial_context(k: LineClass): bool
fun line_is_final_context(k: LineClass): bool
fun line_is_brahmic(t: LineToken): bool
fun line_is_brahmic_base(t: LineToken): bool
