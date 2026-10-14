#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position.sats"
staload "data_font/glyph_position_work.sats"
implement glyph_position_ready(status) = case+ status of
  | PositionReady() => true | PositionDomain() => false | PositionReference() => false
  | PositionCapacity() => false | PositionOverflow() => false | PositionVariation() => false
implement glyph_position_checked(value) = if value < ~2147483648LL orelse value > 2147483647LL
  then @{status=PositionOverflow(),value=0}
  else @{status=PositionReady(),value=airlock_i32(value)}
implement glyph_position_sum(a,b) = glyph_position_checked(g0int2int_int_llint(a)+g0int2int_int_llint(b))
fun rounded(value: llint,units: int): llint = let
  val denominator=g0int2int_int_llint(units)
in if value >= 0LL then (value+denominator/2LL)/denominator
  else ~((~value+denominator/2LL)/denominator) end
implement glyph_position_coordinate(units,ppem,design,pixels) =
  if ilt(units,16) orelse igt(units,16384) orelse ilt(ppem,1) orelse igt(ppem,65535)
  then @{status=PositionDomain(),value=0} else let
    val numerator=g0int2int_int_llint(design)*g0int2int_int_llint(ppem)*64LL
    val device=g0int2int_int_llint(pixels)*64LL
  in glyph_position_checked(rounded(numerator,units)+device) end
