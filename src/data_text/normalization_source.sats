staload "mem.sats"
staload "data_text/normalization_types.sats"
staload "data_text/normalization_draft.sats"
typedef NormalizationMappingHeader = @{kind=DecompositionKind, start=int, valid=bool}
fun normalization_mapping_header(source: !Buf, start: int, finish: int): NormalizationMappingHeader
fun normalization_source_row(source: !Buf, start: int, finish: int, rows: &Buf >> _, maps: &Buf >> _, counts: DraftCounts): DraftCounts
fun normalization_source(source: !Buf): NormalizationDraftLoad
