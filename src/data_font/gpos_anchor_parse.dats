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
fun accepted(b: !Buf,s: OtSpan,kind: OtAnchorKind,point: int,dx: OtAdjustment,dy: OtAdjustment): OtAnchorRead =
  AnchorAccepted(@{kind=kind,x=ot_value_signed16(ot_u16(b,s,2)),y=ot_value_signed16(ot_u16(b,s,4)),
    point=point,dx=dx,dy=dy})
fun y_device(b: !Buf,s: OtSpan,dx: OtAdjustment): OtAnchorRead =
  case+ ot_adjustment_parse(b,s,ot_u16(b,s,8),10) of
  | ~AdjustmentRejected(e) => AnchorRejected(e)
  | ~AdjustmentAccepted(dy) => accepted(b,s,AnchorDevices(),0,dx,dy)
fun devices(b: !Buf,s: OtSpan): OtAnchorRead =
  if ilt(s.length,10) then AnchorRejected(ot_error(OtBounds(),s)) else
    case+ ot_adjustment_parse(b,s,ot_u16(b,s,6),10) of
    | ~AdjustmentRejected(e) => AnchorRejected(e) | ~AdjustmentAccepted(dx) => y_device(b,s,dx)
fun format_of(b: !Buf,s: OtSpan): OtAnchorRead = let val a=ot_adjustment_absent() in
  case+ ot_u16(b,s,0) of
  | 1 => accepted(b,s,AnchorCoordinates(),0,a,a)
  | 2 => if ilt(s.length,8) then AnchorRejected(ot_error(OtBounds(),s))
      else accepted(b,s,AnchorContour(),ot_u16(b,s,6),a,a)
  | 3 => devices(b,s) | _ => AnchorRejected(ot_error(OtFormat(),s)) end
implement ot_anchor_parse(b,s) =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,6) then AnchorRejected(ot_error(OtBounds(),s))
  else format_of(b,s)
