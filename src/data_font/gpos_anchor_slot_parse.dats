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
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/gpos_anchor_cache.sats"
fun missing(parent: OtSpan,presence: OtAnchorPresence): OtAnchorSlotRead = case+ presence of
  | AnchorOptional() => AnchorSlotAccepted(ot_anchor_missing())
  | AnchorRequired() => AnchorSlotRejected(ot_error(OtReference(),parent))
implement ot_anchor_slot_parse(b,parent,offset,floor,presence) =
  if not(ot_span_valid(b,parent)) orelse ilt(floor,0) orelse igt(floor,parent.length)
    then AnchorSlotRejected(ot_error(OtBounds(),parent)) else let
  val child=ot_optional_child(parent,offset,floor)
in case+ child.kind of
  | ChildMissing() => missing(parent,presence)
  | ChildInvalid() => AnchorSlotRejected(ot_error(OtBounds(),parent))
  | ChildPresent() => case+ ot_anchor_parse(b,child.span) of
    | ~AnchorRejected(e) => AnchorSlotRejected(e)
    | ~AnchorAccepted(a) => AnchorSlotAccepted(@{kind=AnchorPresent(),anchor=a}) end
