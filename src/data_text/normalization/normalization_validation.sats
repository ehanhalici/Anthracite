staload "mem.sats"
staload "data_text/normalization/normalization_types.sats"
fun normalization_header_read(bytes: !Buf): NormalizationHeader
fun normalization_header_valid(bytes: !Buf, header: NormalizationHeader): bool
fun normalization_structure_valid(bytes: !Buf, header: NormalizationHeader): bool
fun normalization_graph_valid(data: !NormalizationData): bool
fun normalization_pairs_valid(data: !NormalizationData): bool
