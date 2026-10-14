#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_lookups.sats"
staload "data_font/ot_layout_extension.sats"
fun entry{kind:int}(b: !Buf,s: OtSpan,domain: OtLayoutDomain(kind),i: int,floor: int): OtExtensionRead(kind) = let
  val child=ot_optional_child(s,ot_u16(b,s,iadd(6,imul(i,2))),floor)
in case+ child.kind of
  | ChildMissing() => ExtensionRejected(ot_error(OtBounds(),s))
  | ChildInvalid() => ExtensionRejected(ot_error(OtBounds(),s))
  | ChildPresent() => ot_extension_parse(b,child.span,domain) end
fun rest{n:nat}{kind:int} .<n>. (n: int(n),b: !Buf,s: OtSpan,domain: OtLayoutDomain(kind),
  expected: OtLookupKind(kind),i: int,floor: int): Option_vt(OtError) =
  if n = 0 then None_vt() else case+ entry(b,s,domain,i,floor) of
  | ~ExtensionRejected(e) => Some_vt(e)
  | ~ExtensionAccepted(v) =>
    if ine(ot_lookup_kind_code(v.action),ot_lookup_kind_code(expected))
    then Some_vt(ot_error(OtFormat(),v.span))
    else rest(n-1,b,s,domain,expected,iadd(i,1),floor)
implement ot_extension_lookup_validate(b,s,domain,count,floor) =
  if not(ot_span_valid(b,s)) orelse ilt(count,0) orelse not(ot_rows_fit(s,6,count,2))
  then Some_vt(ot_error(OtBounds(),s))
  else if ilt(floor,iadd(6,imul(count,2))) orelse igt(floor,s.length)
  then Some_vt(ot_error(OtBounds(),s))
  else if ieq(count,0) then None_vt() else case+ entry(b,s,domain,0,floor) of
  | ~ExtensionRejected(e) => Some_vt(e)
  | ~ExtensionAccepted(v) => rest(airlock_nat(isub(count,1)),b,s,domain,v.action,1,floor)
