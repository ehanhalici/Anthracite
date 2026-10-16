#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization/normalization_types.sats"
staload "data_text/normalization/normalization_draft.sats"
staload "data_text/unicode/unicode_sort.sats"
staload "data_text/normalization/normalization_row.sats"
staload "data_text/normalization/normalization_pairs.sats"

fun composable(row: NormalizationRow): bool =
  normalization_is_canonical(row.kind) andalso ieq(row.count,2) andalso not(row.excluded)

fun pair_count {n:nat} .<n>. (n: int(n), draft: !NormalizationDraft, i: int, total: int): int =
  if n = 0 then total else let
    val next = iadd(total,if composable(normalization_draft_row(draft,i)) then 1 else 0)
  in pair_count(n-1,draft,iadd(i,1),next) end

implement normalization_draft_pair_count(draft) =
  pair_count(airlock_nat(normalization_draft_count(draft)),draft,0,0)

fun emit_pair(draft: !NormalizationDraft, output: !Buf, row: NormalizationRow, total: int): void = let
  val at = imul(total,3)
  val () = buf_set32(output,at,normalization_draft_mapping(draft,row.offset))
  val () = buf_set32(output,iadd(at,1),normalization_draft_mapping(draft,iadd(row.offset,1)))
in buf_set32(output,iadd(at,2),row.cp) end

fun emit {n:nat} .<n>. (n: int(n), draft: !NormalizationDraft, output: !Buf, i: int, total: int): void =
  if n = 0 then () else let
    val row = normalization_draft_row(draft,i)
    val matches = composable(row)
    val () = if matches then emit_pair(draft,output,row,total) else ()
    val next = iadd(total,if matches then 1 else 0)
  in emit(n-1,draft,output,iadd(i,1),next) end

implement normalization_draft_pairs(draft) = let
  val count = normalization_draft_pair_count(draft)
  val output = buf_make(imul(count,12))
  val () = emit(airlock_nat(normalization_draft_count(draft)),draft,output,0,0)
  val () = unicode_rows_sort(output,count,3,1)
  val () = unicode_rows_sort(output,count,3,0)
  val () = buf_set_len(output,imul(count,12))
in output end
