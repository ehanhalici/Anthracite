#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_values.sats"
staload "data_font/gpos_value_work.sats"
fun device(b: !Buf,s: OtSpan,at: int,field: int,floor: int): OtAdjustmentRead =
  ot_adjustment_parse(b,s,ot_value_device_offset(b,s,at,field),floor)
fun y_advance(b: !Buf,s: OtSpan,at: int,f: OtValueFormat,floor: int,xp: OtAdjustment,
  yp: OtAdjustment,xa: OtAdjustment): OtValueRead = case+ device(b,s,at,f.yad,floor) of
  | ~AdjustmentRejected(e) => ValueRejected(e) | ~AdjustmentAccepted(ya) =>
    ValueAccepted(@{units=ot_value_units(b,s,at,f),xPlace=xp,yPlace=yp,xAdvance=xa,yAdvance=ya})
fun x_advance(b: !Buf,s: OtSpan,at: int,f: OtValueFormat,floor: int,xp: OtAdjustment,
  yp: OtAdjustment): OtValueRead = case+ device(b,s,at,f.xad,floor) of
  | ~AdjustmentRejected(e) => ValueRejected(e)
  | ~AdjustmentAccepted(xa) => y_advance(b,s,at,f,floor,xp,yp,xa)
fun y_place(b: !Buf,s: OtSpan,at: int,f: OtValueFormat,floor: int,xp: OtAdjustment): OtValueRead =
  case+ device(b,s,at,f.yd,floor) of
  | ~AdjustmentRejected(e) => ValueRejected(e)
  | ~AdjustmentAccepted(yp) => x_advance(b,s,at,f,floor,xp,yp)
implement ot_value_parse(b,s,at,f,floor) =
  if not(ot_span_valid(b,s)) orelse ilt(at,0) orelse igt(at,s.length)
    orelse ilt(f.size,0) orelse igt(f.size,isub(s.length,at))
    orelse ilt(floor,iadd(at,f.size)) orelse igt(floor,s.length)
    then ValueRejected(ot_error(OtBounds(),s)) else case+ device(b,s,at,f.xd,floor) of
    | ~AdjustmentRejected(e) => ValueRejected(e)
    | ~AdjustmentAccepted(xp) => y_place(b,s,at,f,floor,xp)
