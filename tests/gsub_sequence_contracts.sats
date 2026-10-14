staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gsub_sequence_types.sats"
fun sequence_fixture(): Buf
fun sequence_test_formats(): int
fun sequence_test_errors(): int
fun sequence_test_stress(): int
fun sequence_test_extension(): int
fun sequence_test_fonts(path: string): int
