staload "mem.sats"
staload "data_text/normalization_types.sats"
fun normalization_header(data: !NormalizationData): NormalizationHeader
fun normalization_info(data: !NormalizationData, cp: int): NormalizationRow
(* Index belongs to an already checked nonempty mapping span. *)
fun normalization_mapping(data: !NormalizationData, index: int): int
fun normalization_compose_pair(data: !NormalizationData, left: int, right: int): int
fun normalization_dispose(data: NormalizationData): void
