#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/glyph/position/glyph_position_work.sats"
staload "font/glyph/position/glyph_position_contracts.sats"
fun sample(units: int,ppem: int,design: int,pixels: int,want: int): int = let
  val v=glyph_position_coordinate(units,ppem,design,pixels)
in if glyph_position_ready(v.status) andalso ieq(v.value,want) then 0 else 1 end
fun overflow(): int = let val c=glyph_position_sum(SIGNED_INT_MAX_VALUE,1)
in case+ c.status of | PositionOverflow() => 0 | PositionReady() => 1 | PositionDomain() => 1
  | PositionReference() => 1 | PositionCapacity() => 1 | PositionVariation() => 1 end
implement position_test_scale_cases() = sample(1024,16,10,0,10)+sample(1000,16,275,0,282)
  +sample(1024,16,10,2,138)+sample(2048,16,1,0,1)+sample(2048,16,~1,0,~1)+overflow()
