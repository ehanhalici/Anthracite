#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/sfnt.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gdef_types.sats"
staload "data_font/ot_item_variation_types.sats"
staload "data_font/ot_item_variation.sats"

fun axis_scalar(start: int, peak: int, finish: int, c: int): int =
  if igt(start, peak) orelse igt(peak, finish) then 0
  else if ieq(peak, 0) then 65536
  else if ilt(c, start) orelse igt(c, finish) then 0
  else if ieq(c, peak) then 65536
  else if ilt(c, peak) then
    (if ieq(peak, start) then 0
     else let
       val num = g0int2int_int_llint(isub(c, start)) * 65536LL
       val den = g0int2int_int_llint(isub(peak, start))
     in airlock_i32(num / den) end)
  else
    (if ieq(finish, peak) then 0
     else let
       val num = g0int2int_int_llint(isub(finish, c)) * 65536LL
       val den = g0int2int_int_llint(isub(finish, peak))
     in airlock_i32(num / den) end)

fun axis_coord(coords: !Buf, axis: int, count: int): int =
  if ilt(axis, count) then let
    val at_0 = imul(axis, 2)
    val at_8 = iadd(8, imul(axis, 2))
  in if ige(buf_len(coords), iadd(at_8, 2)) andalso ieq(buf_len(coords), iadd(8, imul(count, 2)))
    then sfnt_signed16(coords, at_8)
    else if ige(buf_len(coords), iadd(at_0, 2)) then sfnt_signed16(coords, at_0)
    else 0 end
  else 0

fun region_scalar_axes {n:nat} .<n>. (
  n: int(n), b: !Buf, s: OtSpan, coords: !Buf, axisCount: int, at: int, acc: int, i: int
): int =
  if n = 0 then acc else if ieq(acc, 0) then 0 else let
    val start = sfnt_signed16(b, iadd(s.offset, at))
    val peak = sfnt_signed16(b, iadd(s.offset, iadd(at, 2)))
    val finish = sfnt_signed16(b, iadd(s.offset, iadd(at, 4)))
    val c = axis_coord(coords, i, axisCount)
    val sc = axis_scalar(start, peak, finish, c)
    val prod = g0int2int_int_llint(acc) * g0int2int_int_llint(sc)
    val nextAcc = airlock_i32(prod / 65536LL)
  in region_scalar_axes(n - 1, b, s, coords, axisCount, iadd(at, 6), nextAcc, iadd(i, 1)) end

implement ot_item_var_region_scalar(b, regions, regionIndex, coords, axisCount) =
  if ilt(regionIndex, 0) orelse ige(regionIndex, regions.regionCount) then 0
  else let
    val regionBytes = imul(regions.axisCount, 6)
    val at = iadd(4, imul(regionIndex, regionBytes))
  in if ilt(regions.span.length, iadd(at, regionBytes)) then 0
    else region_scalar_axes(airlock_nat(regions.axisCount), b, regions.span, coords, axisCount, at, 65536, 0) end
