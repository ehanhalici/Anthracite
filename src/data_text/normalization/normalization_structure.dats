#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization/normalization_types.sats"
staload "data_text/normalization/normalization_validation.sats"
staload "data_text/normalization/normalization_hangul.sats"
staload "data_text/normalization/normalization_row.sats"
extern fun norm_structure_exhausted(): int = "mac#anth_die_int"

fun raw_kind_valid(bytes: !Buf, at: int): bool = let
  val code = buf_get32(bytes,iadd(at,2))
  val excluded = buf_get32(bytes,iadd(at,8))
in ige(code,0) andalso ile(code,2) andalso ige(excluded,0) andalso ile(excluded,1) end

fun row_valid(row: NormalizationRow, h: NormalizationHeader, previous: int, offset: int): bool = let
  val mapping = normalization_has_mapping(row.kind)
  val leaf = ieq(row.count,0) andalso ieq(row.depth,0) andalso ieq(row.canonical,1) andalso ieq(row.compatibility,1) andalso igt(row.ccc,0)
in normalization_scalar_valid(row.cp) andalso igt(row.cp,previous) andalso ige(row.ccc,0) andalso ile(row.ccc,255)
  andalso not(normalization_hangul_syllable(row.cp))
  andalso ieq(row.offset,offset) andalso ige(row.count,0) andalso ile(row.count,isub(h.mappings,offset))
  andalso igt(row.canonical,0) andalso ile(row.canonical,row.compatibility) andalso ile(row.compatibility,h.expansion)
  andalso ige(row.depth,0) andalso ile(row.depth,h.depth)
  andalso (if mapping then igt(row.count,0) andalso igt(row.depth,0) else leaf) end

fun rows {n:nat} .<n>. (
  n: int(n), bytes: !Buf, h: NormalizationHeader, i: int, previous: int, offset: int
): int = if n = 0 then offset else let
  val at = iadd(NORMALIZATION_HEADER_WORDS,imul(i,NORMALIZATION_ROW_WORDS))
in if not(raw_kind_valid(bytes,at)) then ~1 else let
    val row = normalization_row_read(bytes,at)
  in if not(row_valid(row,h,previous,offset)) then ~1
    else rows(n-1,bytes,h,iadd(i,1),row.cp,iadd(row.offset,row.count)) end end

fun mappings {n:nat} .<n>. (n: int(n), bytes: !Buf, at: int): bool =
  if n = 0 then true else normalization_scalar_valid(buf_get32(bytes,at)) andalso mappings(n-1,bytes,iadd(at,1))

implement normalization_structure_valid(bytes,h) = let
  val offset = rows(airlock_nat(h.rows),bytes,h,0,~1,0)
  val base = iadd(NORMALIZATION_HEADER_WORDS,imul(h.rows,NORMALIZATION_ROW_WORDS))
in ieq(offset,h.mappings) andalso mappings(airlock_nat(h.mappings),bytes,base) end
