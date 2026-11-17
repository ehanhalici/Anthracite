staload "mem.sats"
staload "data_text/normalization/normalization_types.sats"
fun normalization_header(data: !NormalizationData): NormalizationHeader
fun normalization_info(data: !NormalizationData, cp: int): NormalizationRow
(* Index belongs to an already checked nonempty mapping span. *)
fun normalization_mapping(data: !NormalizationData, index: int): int
fun normalization_compose_pair(data: !NormalizationData, left: int, right: int): int
fun normalization_dispose(data: NormalizationData): void
(* Contract check: the dense row index equals the binary search below UNICODE_DENSE_SCALARS. *)
fun normalization_dense_match(data: !NormalizationData): bool
