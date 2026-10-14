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
staload "data_font/ot_single_lookup_types.sats"
staload "data_font/ot_single_lookup_work.sats"
fun accepted(h: OtLookupInfo(1),envelope: OtSingleEnvelope): OtSingleHeaderRead =
  SingleHeaderAccepted(@{span=h.span,envelope=envelope,flags=h.flags,count=h.count,
    floor=ot_lookup_header_floor(h),markSet=h.markSet})
fun action(h: OtLookupInfo(1)): OtSingleHeaderRead = case+ h.action of
  | SubSingle() => accepted(h,SingleDirect()) | SubExtension() => accepted(h,SingleExtended())
  | SubMultiple() => SingleHeaderRejected(ot_error(OtUnsupported(),h.span))
  | SubAlternate() => SingleHeaderRejected(ot_error(OtUnsupported(),h.span))
  | SubLigature() => SingleHeaderRejected(ot_error(OtUnsupported(),h.span))
  | SubContext() => SingleHeaderRejected(ot_error(OtUnsupported(),h.span))
  | SubChained() => SingleHeaderRejected(ot_error(OtUnsupported(),h.span))
  | SubReverse() => SingleHeaderRejected(ot_error(OtUnsupported(),h.span))
implement ot_single_header_parse(b,s) =
  case+ ot_lookup_header_parse(b,s,OtSubstitution()) of
  | ~LookupHeaderRejected(e) => SingleHeaderRejected(e)
  | ~LookupHeaderAccepted(h) => action(h)
