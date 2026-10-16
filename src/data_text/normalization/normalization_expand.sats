staload "mem.sats"
staload "data_text/normalization/normalization_types.sats"
typedef ExpansionState = @{pending=int, output=int}
typedef SourceSpan = @{start=int, finish=int}
datatype ExpansionAction = EmitScalar | ExpandMapping | ExpandHangul
fun normalization_expansion_action(kind: DecompositionKind, scope: DecompositionScope, hangul_count: int): ExpansionAction
fun normalization_expand_scalar(data: !NormalizationData, scope: DecompositionScope, cp: int, span: SourceSpan,
  values: !Buf, starts: !Buf, ends: !Buf, stack: !Buf, output: int): int
