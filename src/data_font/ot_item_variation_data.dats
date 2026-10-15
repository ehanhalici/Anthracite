#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/sfnt.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/gdef_types.sats"
staload "data_font/ot_item_variation_types.sats"
staload "data_font/ot_item_variation.sats"

fun round_fixed16(acc: llint): int = let
  val rounded = if acc >= 0LL then (acc + 32768LL) / 65536LL else (acc - 32768LL) / 65536LL
in airlock_i32(rounded) end

fun column_delta(b: !Buf, s: OtSpan, rowAt: int, words: int, k: int): int =
  if ilt(k, words) then sfnt_signed16(b, iadd(s.offset, iadd(rowAt, imul(k, 2))))
  else let
    val raw = buf_get(b, iadd(s.offset, iadd(rowAt, iadd(imul(words, 2), isub(k, words)))))
  in if ige(raw, 128) then isub(raw, 256) else raw end

fun sum_delta_columns {n:nat} .<n>. (
  n: int(n), b: !Buf, s: OtSpan, regions: OtVariationRegionList, words: int,
  coords: !Buf, axisCount: int, rowAt: int, k: int, acc: llint
): llint =
  if n = 0 then acc else let
    val delta = column_delta(b, s, rowAt, words, k)
    val rindex = ot_u16(b, s, iadd(6, imul(k, 2)))
    val sc = ot_item_var_region_scalar(b, regions, rindex, coords, axisCount)
    val term = g0int2int_int_llint(delta) * g0int2int_int_llint(sc)
    val nextAcc = acc + term
  in sum_delta_columns(n - 1, b, s, regions, words, coords, axisCount, rowAt, iadd(k, 1), nextAcc) end

implement ot_item_var_data_delta(
  b, s, regions, inner, coords, axisCount
) = let
  val itemCount = ot_u16(b, s, 0)
  val rawWords = ot_u16(b, s, 2)
  val words = imod(rawWords, 32768)
  val rcount = ot_u16(b, s, 4)
  val rowBytes = iadd(imul(words, 2), isub(rcount, words))
  val deltaOffset = iadd(6, imul(rcount, 2))
  val rowAt = iadd(deltaOffset, imul(inner, rowBytes))
in if ilt(inner, 0) orelse ige(inner, itemCount) orelse ilt(s.length, iadd(rowAt, rowBytes)) then 0
  else round_fixed16(sum_delta_columns(airlock_nat(rcount), b, s, regions, words, coords, axisCount, rowAt, 0, 0LL)) end
