staload "mem.sats"
staload "data_text/normalization_types.sats"
fun normalization_kind_of(code: int): DecompositionKind
fun normalization_kind_code(kind: DecompositionKind): int
fun normalization_has_mapping(kind: DecompositionKind): bool
fun normalization_is_canonical(kind: DecompositionKind): bool
fun normalization_row_read(rows: !Buf, at: int): NormalizationRow
fun normalization_row_write(rows: !Buf, at: int, row: NormalizationRow): void
fun normalization_row_search(rows: !Buf, offset: int, count: int, cp: int): int
fun normalization_default_row(cp: int): NormalizationRow
fun normalization_scalar_valid(cp: int): bool
