staload "mem.sats"
staload "data_text/normalization_types.sats"
typedef NormalizationOrderSpan = @{finish=int, ordered=bool}
typedef NormalizationOrderScalar = @{cp=int, start=int, finish=int, ccc=int}
fun normalization_order_span(classes: !Buf, start: int, total: int): NormalizationOrderSpan
fun normalization_order_maximum(classes: !Buf, total: int): int
fun normalization_order_segment(values: !Buf, starts: !Buf, ends: !Buf, classes: !Buf, permutation: !Buf, counters: !Buf, start: int, size: int): void
fun normalization_order_permute(values: !Buf, starts: !Buf, ends: !Buf, classes: !Buf, permutation: !Buf, start: int, size: int): void

