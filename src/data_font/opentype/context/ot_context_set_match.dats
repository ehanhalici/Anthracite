#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/context/ot_context_pattern.sats"
staload "data_font/opentype/context/ot_context_work.sats"
staload "data_font/opentype/context/ot_context_match_work.sats"
fun rules {n:nat}{kind:int} .<n>. (n: int(n),b: !Buf,info: OtContextInfo,domain: OtLayoutDomain(kind),
  set: OtSpan,input: !Buf,count: int,start: int,inputLimit: int,index: int,atom: OtContextAtom): OtContextMatch(kind) =
  if n = 0 then ot_context_missing(domain) else let
    val child=ot_context_rule(b,set,index)
    val p=ot_context_rule_info(b,child.span,info.mode)
    val matched=ot_context_pattern_fits_input(p,count,start,inputLimit) andalso ot_context_atoms_match(b,info,p,input,start,atom)
  in if matched then ot_context_result(domain,p,index)
    else rules(n-1,b,info,domain,set,input,count,start,inputLimit,iadd(index,1),atom) end
implement ot_context_sets_match(b,info,domain,input,count,start,inputLimit,index,atom) =
  if ilt(index,0) orelse ige(index,info.setCount) then ot_context_missing(domain) else let
    val child=ot_context_set(b,info,index)
  in case+ child.kind of
    | ChildMissing() => ot_context_missing(domain)
    | ChildInvalid() => ot_context_missing(domain)
    | ChildPresent() => rules(airlock_nat(ot_u16(b,child.span,0)),b,info,domain,child.span,input,count,start,inputLimit,0,atom) end
