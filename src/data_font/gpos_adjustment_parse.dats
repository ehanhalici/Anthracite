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
staload "data_font/opentype_device.sats"
implement ot_adjustment_absent() = @{kind=AdjustmentAbsent(),
  device= @{span= @{offset=0,length=0},packing=OtBits2(),first=0,last=0},outer=0,inner=0}
fun child(b: !Buf,s: OtSpan): OtAdjustmentRead = case+ ot_device_parse(b,s) of
  | ~DeviceRejected(e) => AdjustmentRejected(e)
  | ~DeviceAccepted(d) => AdjustmentAccepted(@{kind=AdjustmentDevice(),device=d,outer=0,inner=0})
  | ~DeviceVariation(outer,inner) => let val none=ot_adjustment_absent() in
      AdjustmentAccepted(@{kind=AdjustmentVariation(),device=none.device,outer=outer,inner=inner}) end
implement ot_adjustment_parse(b,parent,offset,floor) =
  if not(ot_span_valid(b,parent)) orelse ilt(floor,0) orelse igt(floor,parent.length)
    then AdjustmentRejected(ot_error(OtBounds(),parent)) else let
    val target=ot_optional_child(parent,offset,floor)
  in case+ target.kind of
    | ChildMissing() => AdjustmentAccepted(ot_adjustment_absent())
    | ChildInvalid() => AdjustmentRejected(ot_error(OtBounds(),parent))
    | ChildPresent() => child(b,target.span) end
