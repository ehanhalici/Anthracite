staload "mem.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/arabic/joining/arabic_join_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
fun arabic_test_bytes(source: string): Buf
fun arabic_test_nominal(text: !ScalarText): GlyphRun(0)
fun arabic_test_plan(): ArabicMaskPlan
fun arabic_test_sequence(map: !PropertyMap(3),plan: !ArabicMaskPlan,source: string,expected: string,context: ArabicContext): int
fun arabic_test_check(run: !GlyphRun(1),text: !ScalarText,expected: !Buf): int
fun arabic_test_masks(): int
fun arabic_test_examples(map: !PropertyMap(3),plan: !ArabicMaskPlan): int
fun arabic_test_boundaries(map: !PropertyMap(3),plan: !ArabicMaskPlan): int
fun arabic_test_rules(map: !PropertyMap(3),plan: !ArabicMaskPlan): int
fun arabic_test_stress(map: !PropertyMap(3),plan: !ArabicMaskPlan): int
fun arabic_test_model(current: ArabicJoining,prior: ArabicJoining,next: ArabicJoining): ArabicForm
fun arabic_test_form_code(form: ArabicForm): int
fun arabic_test_rule_kind(index: int,i: int): ArabicJoining
fun arabic_test_rule_source(index: int): Buf
fun arabic_test_rule_expected(index: int): Buf
