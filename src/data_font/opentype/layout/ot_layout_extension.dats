#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_lookups.sats"
staload "data_font/opentype/layout/ot_layout_extension.sats"
fun action_of{kind:int}(domain: OtLayoutDomain(kind),raw: int): Option_vt(OtLookupKind(kind)) =
  case+ domain of
  | OtSubstitution() => if ieq(raw,7) then None_vt() else ot_lookup_kind_of(domain,raw)
  | OtPositioning() => if ieq(raw,9) then None_vt() else ot_lookup_kind_of(domain,raw)
fun target{kind:int}(b: !Buf,s: OtSpan,action: OtLookupKind(kind)): OtExtensionRead(kind) = let
  val child=ot_optional_child(s,ot_u32(b,s,4),8)
in case+ child.kind of
  | ChildMissing() => ExtensionRejected(ot_error(OtBounds(),s))
  | ChildInvalid() => ExtensionRejected(ot_error(OtBounds(),s))
  | ChildPresent() => if ilt(child.span.length,2) then ExtensionRejected(ot_error(OtBounds(),child.span))
    else ExtensionAccepted(@{span=child.span,action=action}) end
implement ot_extension_parse(b,s,domain) =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,8) then ExtensionRejected(ot_error(OtBounds(),s))
  else if ine(ot_u16(b,s,0),1) then ExtensionRejected(ot_error(OtFormat(),s))
  else case+ action_of(domain,ot_u16(b,s,2)) of
    | ~None_vt() => ExtensionRejected(ot_error(OtFormat(),s))
    | ~Some_vt(action) => target(b,s,action)
