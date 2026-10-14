#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_lookup_header.sats"
staload "data_font/ot_position_lookup_types.sats"
staload "data_font/ot_position_lookup_work.sats"
fun payload(b: !Buf,h: OtLookupInfo(2),glyphs: int,i: int): OtPositionPayloadRead = let
  val child=ot_optional_child(h.span,ot_u16(b,h.span,iadd(6,imul(i,2))),ot_lookup_header_floor(h))
in case+ child.kind of | ChildMissing() => PositionPayloadRejected(ot_error(OtBounds(),h.span))
  | ChildInvalid() => PositionPayloadRejected(ot_error(OtBounds(),h.span))
  | ChildPresent() => ot_position_payload_resolve(b,child.span,glyphs,h.action) end
fun read{n,k:nat} .<n>. (left: int(n),b: !Buf,h: OtLookupInfo(2),glyphs: int,
  xs: list_vt(OtPositionPayload,k),count: int(k),remaining: &int >> _): OtPositionTablesRead =
  if left = 0 then PositionTablesAccepted(ot_position_tables_make(xs,count))
  else case+ payload(b,h,glyphs,left-1) of
  | ~PositionPayloadRejected(e) => let val ()=ot_position_payload_list_dispose(xs) in PositionTablesRejected(e) end
  | ~PositionPayloadAccepted(p) => if ot_position_payload_charge(p,remaining)
    then read(left-1,b,h,glyphs,list_vt_cons(p,xs),count+1,remaining)
    else let val ()=ot_position_payload_dispose(p) and ()=ot_position_payload_list_dispose(xs)
      in PositionTablesRejected(ot_error(OtCapacity(),h.span)) end
implement ot_position_tables_read(b,h,glyphs) = let var remaining: int=MAX_REC_FUEL
in read(airlock_nat(h.count),b,h,glyphs,list_vt_nil(),0,remaining) end
