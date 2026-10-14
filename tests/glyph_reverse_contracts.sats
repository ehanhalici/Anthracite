staload "mem.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/ot_reverse_lookup_types.sats"
fun reverse_pass_parse(b: !Buf): OtReverseLookup
fun reverse_pass_ready(s: GlyphPassStatus): bool
fun reverse_pass_table(): Buf
fun reverse_pass_run(count: int,errors: &int >> int): GlyphRun(1)
fun reverse_pass_basic(): int
fun reverse_pass_cache(): int
fun reverse_pass_rollback(): int
fun reverse_pass_masks(): int
fun reverse_pass_stress(): int
