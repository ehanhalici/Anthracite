#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization/normalization_types.sats"
staload "data_text/normalization/normalization_draft.sats"
staload "data_text/normalization/normalization_row.sats"

implement normalization_draft_count(draft) = let val+ NormalizationDraft(rows,maps,n,m) = draft in n end
implement normalization_draft_mappings(draft) = let val+ NormalizationDraft(rows,maps,n,m) = draft in m end
implement normalization_draft_row(draft,i) = let val+ NormalizationDraft(rows,maps,n,m) = draft in
  normalization_row_read(rows,imul(i,NORMALIZATION_ROW_WORDS)) end
implement normalization_draft_find(draft,cp) = let val+ NormalizationDraft(rows,maps,n,m) = draft in
  normalization_row_search(rows,0,n,cp) end
implement normalization_draft_mapping(draft,i) = let val+ NormalizationDraft(rows,maps,n,m) = draft in buf_get32(maps,i) end
implement normalization_draft_update(draft,i,row) = let val+ NormalizationDraft(rows,maps,n,m) = draft in
  normalization_row_write(rows,imul(i,NORMALIZATION_ROW_WORDS),row) end
implement normalization_draft_dispose(draft) = let
  val+ ~NormalizationDraft(rows,maps,n,m) = draft
  val () = buf_free(rows)
in buf_free(maps) end
