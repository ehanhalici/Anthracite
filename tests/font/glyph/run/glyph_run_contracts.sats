staload "mem.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
fun run_test_updated(status: GlyphEditStatus): bool
fun run_test_rejected(status: GlyphEditStatus): bool
fun run_test_unchanged(status: GlyphEditStatus): bool
fun run_test_take{phase:int}(edit: GlyphRunEdit(phase),expected: (GlyphEditStatus) -<fun1> bool,errors: &int >> _): GlyphRun(phase)
fun run_test_nominal(capacity: int,count: int,errors: &int >> _): GlyphRun(0)
fun run_test_indices(a: int,b: int): Buf
fun run_test_basic(): int
fun run_test_ligatures(): int
fun run_test_positions(): int
fun run_test_stress(): int
