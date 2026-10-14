staload "mem.sats"
staload "data_text/normalization_types.sats"

datavtype NormalizationDraft = NormalizationDraft of (Buf, Buf, int, int)
datavtype NormalizationDraftLoad = DraftLoaded of NormalizationDraft | DraftRejected of NormalizationError
typedef DraftCounts = @{rows=int, mappings=int, valid=bool}
fun normalization_draft_count(draft: !NormalizationDraft): int
fun normalization_draft_mappings(draft: !NormalizationDraft): int
fun normalization_draft_row(draft: !NormalizationDraft, i: int): NormalizationRow
fun normalization_draft_find(draft: !NormalizationDraft, cp: int): int
fun normalization_draft_mapping(draft: !NormalizationDraft, i: int): int
fun normalization_draft_update(draft: !NormalizationDraft, i: int, row: NormalizationRow): void
fun normalization_draft_dispose(draft: NormalizationDraft): void
