#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8.sats"
staload "data_text/normalization_types.sats"
staload "data_text/normalization_engine.sats"
staload "data_text/normalization_bounds.sats"
staload "data_text/normalization_data.sats"

fun expanded_size(row: NormalizationRow, scope: DecompositionScope): int = case+ scope of
  | CanonicalScope() => row.canonical | CompatibilityScope() => row.compatibility

fun count {n:nat} .<n>. (
  n: int(n), data: !NormalizationData, text: !ScalarText, scope: DecompositionScope, i: int, total: int
): int = if n = 0 then total else let
  val row = normalization_info(data,scalar_value(text,i))
  val next = normalization_count_sum(total,expanded_size(row,scope))
in count(n-1,data,text,scope,iadd(i,1),next) end

implement normalization_expanded_count(data,text,scope) =
  normalization_expanded_count_range(data,text,0,scalar_count(text),scope)
implement normalization_expanded_count_range(data,text,start,finish,scope) =
  if ilt(start,0) orelse ilt(finish,start) orelse igt(finish,scalar_count(text)) then ~1
  else count(airlock_span(start,finish),data,text,scope,start,0)
