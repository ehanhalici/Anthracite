staload "data_text/normalization/normalization_types.sats"
fun normalization_graph_initial(row: NormalizationRow): NormalizationRow
fun normalization_graph_accumulate(parent: NormalizationRow, child: NormalizationRow): NormalizationRow
fun normalization_graph_finish(row: NormalizationRow): NormalizationRow
