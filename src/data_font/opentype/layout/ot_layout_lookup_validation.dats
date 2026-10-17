#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/tables/opentype_lookup_flags.sats"
staload "data_font/opentype/layout/ot_layout_lookups.sats"
staload "data_font/opentype/layout/ot_layout_work.sats"
staload "data_font/opentype/layout/ot_layout_extension.sats"

fun subtables {n:nat} .<n>. (n: int(n),b: !Buf,s: OtSpan,index: int,count: int,floor: int): bool =
  if n = 0 then true else let
    val child=ot_optional_child(s,ot_u16(b,s,iadd(6,imul(index,2))),floor)
  in case+ child.kind of
    | ChildMissing() => false | ChildInvalid() => false
    | ChildPresent() => ige(child.span.length,2) andalso subtables(n-1,b,s,iadd(index,1),count,floor) end

fun flagged{kind:int}(b: !Buf,s: OtSpan,action: OtLookupKind(kind),f: OtLookupFlags,
  caps: OtGdefCapabilities,remaining: &int >> _): Option_vt(OtError) = let
  val count=ot_u16(b,s,4)
  val floor=iadd(iadd(6,imul(count,2)),if f.useMarkSet then 2 else 0)
in if igt(floor,s.length) then Some_vt(ot_error(OtBounds(),s))
  else if not(ot_layout_charge(remaining,iadd(count,1))) then Some_vt(ot_error(OtCapacity(),s)) else let
    val set=if f.useMarkSet then ot_u16(b,s,isub(floor,2)) else 0
  in if not(ot_lookup_dependencies(f,set,caps)) then Some_vt(ot_error(OtReference(),s))
    else if not(subtables(airlock_nat(count),b,s,0,count,floor)) then Some_vt(ot_error(OtBounds(),s))
    else ot_lookup_extension_validate(b,s,action,count,floor) end end

fun lookup{kind:int}(b: !Buf,s: OtSpan,domain: OtLayoutDomain(kind),caps: OtGdefCapabilities,remaining: &int >> _): Option_vt(OtError) =
  if ilt(s.length,6) then Some_vt(ot_error(OtBounds(),s)) else case+ ot_lookup_kind_of(domain,ot_u16(b,s,0)) of
  | ~None_vt() => Some_vt(ot_error(OtFormat(),s))
  | ~Some_vt(action) => case+ ot_lookup_flags_of(ot_u16(b,s,2)) of
    | ~FlagsRejected(reason) => Some_vt(ot_error(reason,s))
    | ~FlagsAccepted(f) => flagged(b,s,action,f,caps,remaining)

fun lookups {n:nat}{kind:int} .<n>. (n: int(n),b: !Buf,info: OtLayoutInfo,
  domain: OtLayoutDomain(kind),caps: OtGdefCapabilities,index: int,remaining: &int >> _): Option_vt(OtError) =
  if n = 0 then None_vt() else let val child=ot_lookup_span(b,info,index) in
    case+ child.kind of
    | ChildMissing() => Some_vt(ot_error(OtBounds(),info.lookups))
    | ChildInvalid() => Some_vt(ot_error(OtBounds(),info.lookups))
    | ChildPresent() => case+ lookup(b,child.span,domain,caps,remaining) of
      | ~Some_vt(e) => Some_vt(e) | ~None_vt() => lookups(n-1,b,info,domain,caps,iadd(index,1),remaining) end

implement ot_lookups_work(b,info,domain,caps,remaining) =
  if not(ot_rows_fit(info.lookups,2,info.lookupCount,2)) then Some_vt(ot_error(OtBounds(),info.lookups))
  else if not(ot_layout_charge(remaining,info.lookupCount)) then Some_vt(ot_error(OtCapacity(),info.lookups))
  else lookups(airlock_nat(info.lookupCount),b,info,domain,caps,0,remaining)

implement ot_lookups_validate(b,info,domain,caps) = let var remaining: int=MAX_REC_FUEL in
  ot_lookups_work(b,info,domain,caps,remaining) end
