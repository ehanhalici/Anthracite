staload "data_text/normalization_types.sats"
typedef HangulParts = @{first=int, second=int, third=int, count=int}
fun normalization_hangul_parts(cp: int): HangulParts
fun normalization_hangul_syllable(cp: int): bool
fun normalization_hangul_compose(left: int, right: int): int
fun normalization_leaf_info(cp: int): NormalizationRow
