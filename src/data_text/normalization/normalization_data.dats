#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization/normalization_types.sats"
staload "data_text/normalization/normalization_hangul.sats"
staload "data_text/normalization/normalization_row.sats"
staload "data_text/normalization/normalization_data.sats"

implement normalization_header(data) = let val+ NormalizationData(bytes,header) = data in header end

fun dense_base(bytes: !Buf): int = isub(idiv(buf_len(bytes),WORD32_BYTES),UNICODE_DENSE_SCALARS)
fun row_of(bytes: !Buf,header: NormalizationHeader,cp: int): int =
  if ige(cp,0) andalso ilt(cp,UNICODE_DENSE_SCALARS) then buf_get32(bytes,iadd(dense_base(bytes),cp))
  else normalization_row_search(bytes,NORMALIZATION_HEADER_WORDS,header.rows,cp)
implement normalization_dense_match(data) = let
  val+ NormalizationData(bytes,header) = data
  fun go{n:nat} .<n>. (n: int(n),bytes: !Buf,header: NormalizationHeader,cp: int): bool =
    if n = 0 then true
    else ieq(row_of(bytes,header,cp),normalization_row_search(bytes,NORMALIZATION_HEADER_WORDS,header.rows,cp))
      andalso go(n-1,bytes,header,iadd(cp,1))
in go(airlock_nat(UNICODE_DENSE_SCALARS),bytes,header,0) end
implement normalization_info(data,cp) = let
  val+ NormalizationData(bytes,header) = data
  val row = row_of(bytes,header,cp)
in if ilt(row,0) then normalization_leaf_info(cp)
  else normalization_row_read(bytes,iadd(NORMALIZATION_HEADER_WORDS,imul(row,NORMALIZATION_ROW_WORDS))) end

implement normalization_mapping(data,index) = let
  val+ NormalizationData(bytes,header) = data
  val base = iadd(NORMALIZATION_HEADER_WORDS,imul(header.rows,NORMALIZATION_ROW_WORDS))
in buf_get32(bytes,iadd(base,index)) end

extern fun compose_search_exhausted(): int = "mac#anth_die_int"

fun search_pair {n:nat} .<n>. (
  n: int(n), bytes: !Buf, base: int, left: int, right: int, low: int, high: int
): int = if ige(low,high) then ~1 else if n = 0 then compose_search_exhausted() else let
  val mid = iadd(low,idiv(isub(high,low),2))
  val at = iadd(base,imul(mid,3))
  val first = buf_get32(bytes,at)
  val second = buf_get32(bytes,iadd(at,1))
  val smaller = ilt(left,first) orelse (ieq(left,first) andalso ilt(right,second))
  val larger = igt(left,first) orelse (ieq(left,first) andalso igt(right,second))
in if smaller then search_pair(n-1,bytes,base,left,right,low,mid)
  else if larger then search_pair(n-1,bytes,base,left,right,iadd(mid,1),high)
  else buf_get32(bytes,iadd(at,2)) end

implement normalization_compose_pair(data,left,right) = let
  val hangul = normalization_hangul_compose(left,right)
in if ige(hangul,0) then hangul else let
    val+ NormalizationData(bytes,header) = data
    val base = iadd(iadd(NORMALIZATION_HEADER_WORDS,imul(header.rows,NORMALIZATION_ROW_WORDS)),header.mappings)
  in search_pair(airlock_nat(iadd(header.pairs,1)),bytes,base,left,right,0,header.pairs) end end

implement normalization_dispose(data) = let val+ ~NormalizationData(bytes,header) = data in buf_free(bytes) end
