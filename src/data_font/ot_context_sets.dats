#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_work.sats"
staload "data_font/ot_context_pattern.sats"
staload "data_font/ot_context_work.sats"
fun rules {n:nat}{kind:int} .<n>. (n: int(n),b: !Buf,info: OtContextInfo,domain: OtLayoutDomain(kind),set: OtSpan,
  remaining: &int >> _,i: int): Option_vt(OtError) =
  if n = 0 then None_vt() else let val child=ot_context_rule(b,set,i) in
    case+ child.kind of
    | ChildMissing() => Some_vt(ot_error(OtBounds(),set))
    | ChildInvalid() => Some_vt(ot_error(OtBounds(),set))
    | ChildPresent() => case+ ot_context_rule_parse(b,child.span,info.mode) of
      | ~PatternRejected(e) => Some_vt(e) | ~PatternAccepted(p) =>
        case+ ot_context_rule_validate(b,p,info.encoding,info.glyphs,info.lookups,domain,remaining) of
        | ~Some_vt(e) => Some_vt(e) | ~None_vt() => rules(n-1,b,info,domain,set,remaining,iadd(i,1)) end
fun set{kind:int}(b: !Buf,info: OtContextInfo,domain: OtLayoutDomain(kind),s: OtSpan,remaining: &int >> _): Option_vt(OtError) =
  if ilt(s.length,2) then Some_vt(ot_error(OtBounds(),s)) else let val count=ot_u16(b,s,0) in
    if not(ot_rows_fit(s,2,count,2)) then Some_vt(ot_error(OtBounds(),s))
    else if not(ot_layout_charge(remaining,iadd(count,1))) then Some_vt(ot_error(OtCapacity(),s))
    else rules(airlock_nat(count),b,info,domain,s,remaining,0) end
fun sets {n:nat}{kind:int} .<n>. (n: int(n),b: !Buf,info: OtContextInfo,domain: OtLayoutDomain(kind),remaining: &int >> _,i: int): Option_vt(OtError) =
  if n = 0 then None_vt() else let val child=ot_context_set(b,info,i) in
    case+ child.kind of
    | ChildMissing() => sets(n-1,b,info,domain,remaining,iadd(i,1))
    | ChildInvalid() => Some_vt(ot_error(OtBounds(),info.span))
    | ChildPresent() => case+ set(b,info,domain,child.span,remaining) of
      | ~Some_vt(e) => Some_vt(e) | ~None_vt() => sets(n-1,b,info,domain,remaining,iadd(i,1)) end
implement ot_context_validate(b,info,domain) = let var remaining: int=MAX_REC_FUEL in
  case+ info.encoding of
  | ContextCoverages() => ot_context_rule_validate(b,info.pattern,ContextCoverages(),info.glyphs,info.lookups,domain,remaining)
  | ContextGlyphs() => sets(airlock_nat(info.setCount),b,info,domain,remaining,0)
  | ContextClasses() => sets(airlock_nat(info.setCount),b,info,domain,remaining,0) end
