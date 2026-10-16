staload "mem.sats"
datavtype NormalizationGraph = NormalizationGraph of (Buf, Buf, Buf, Buf, Buf, Buf)
fun norm_graph_make(rows: int, mappings: int): NormalizationGraph
fun norm_graph_dispose(graph: NormalizationGraph): void
fun norm_graph_head(graph: !NormalizationGraph, node: int): int
fun norm_graph_pending(graph: !NormalizationGraph, node: int): int
fun norm_graph_target(graph: !NormalizationGraph, edge: int): int
fun norm_graph_next(graph: !NormalizationGraph, edge: int): int
fun norm_graph_add(graph: !NormalizationGraph, child: int, parent: int): void
fun norm_graph_push(graph: !NormalizationGraph, node: int): void
fun norm_graph_pop(graph: !NormalizationGraph): int
fun norm_graph_processed(graph: !NormalizationGraph): int
fun norm_graph_complete_dependency(graph: !NormalizationGraph, node: int): bool
