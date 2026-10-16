#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization/normalization_types.sats"
staload "data_text/normalization/normalization_validation.sats"
staload "data_text/normalization/normalization_row.sats"
staload "data_text/normalization/normalization_data.sats"

fun pair_valid(data: !NormalizationData, left: int, right: int, cp: int): bool = let
  val row = normalization_info(data,cp)
  val first = normalization_info(data,left)
in normalization_scalar_valid(left) andalso normalization_scalar_valid(right) andalso normalization_scalar_valid(cp)
  andalso normalization_is_canonical(row.kind) andalso not(row.excluded) andalso ieq(row.count,2)
  andalso ieq(normalization_mapping(data,row.offset),left)
  andalso ieq(normalization_mapping(data,iadd(row.offset,1)),right) andalso ieq(first.ccc,0) end

fun pairs {n:nat} .<n>. (
  n: int(n), data: !NormalizationData, bytes: !Buf, at: int, previous_left: int, previous_right: int
): bool = if n = 0 then true else let
  val left = buf_get32(bytes,at)
  val right = buf_get32(bytes,iadd(at,1))
  val cp = buf_get32(bytes,iadd(at,2))
  val increasing = igt(left,previous_left) orelse (ieq(left,previous_left) andalso igt(right,previous_right))
in increasing andalso pair_valid(data,left,right,cp)
  andalso pairs(n-1,data,bytes,iadd(at,3),left,right) end

fun eligible(data: !NormalizationData, row: NormalizationRow): bool =
  if not(normalization_is_canonical(row.kind)) orelse row.excluded orelse ine(row.count,2) then false else let
    val first = normalization_info(data,normalization_mapping(data,row.offset))
  in ieq(first.ccc,0) end

fun expected_pairs {n:nat} .<n>. (n: int(n), data: !NormalizationData, i: int, total: int): int =
  if n = 0 then total else let
    val+ NormalizationData(bytes,h) = data
    val at = iadd(NORMALIZATION_HEADER_WORDS,imul(i,NORMALIZATION_ROW_WORDS))
    val row = normalization_row_read(bytes,at)
    val count = if eligible(data,row) then 1 else 0
  in expected_pairs(n-1,data,iadd(i,1),iadd(total,count)) end

implement normalization_pairs_valid(data) = let
  val+ NormalizationData(bytes,h) = data
  val base = iadd(iadd(NORMALIZATION_HEADER_WORDS,imul(h.rows,NORMALIZATION_ROW_WORDS)),h.mappings)
in ieq(h.pairs,expected_pairs(airlock_nat(h.rows),data,0,0))
  andalso pairs(airlock_nat(h.pairs),data,bytes,base,~1,~1) end
