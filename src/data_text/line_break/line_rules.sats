staload "data_text/line_break/line_types.sats"
fun line_rules_hard(c: LineContext): LineDecision
fun line_rules_glue(c: LineContext): LineDecision
fun line_rules_punctuation(c: LineContext): LineDecision
fun line_rules_quotes(c: LineContext): LineDecision
fun line_rules_words(c: LineContext): LineDecision
fun line_rules_numbers(c: LineContext): LineDecision
fun line_rules_syllables(c: LineContext): LineDecision
fun line_rules_final(c: LineContext): LineDecision
fun line_decide(c: LineContext): LineDecision
