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
staload "data_font/ot_context.sats"
staload "data_font/ot_context_work.sats"
staload "data_font/ot_context_pattern.sats"
fun merged(p: OtContextPattern,old: OtContextLimits): OtContextLimits =
  @{back=imax(p.backCount,old.back),input=imax(p.inputCount,old.input),look=imax(p.lookCount,old.look)}
extern fun context_limits_failed(): int = "mac#anth_die_int"
fun pattern(b: !Buf,info: OtContextInfo,child: OtChild): OtContextPattern = case+ child.kind of
  | ChildPresent() => ot_context_rule_info(b,child.span,info.mode)
  | ChildMissing() => let val failed=context_limits_failed() in ot_context_rule_info(b,child.span,info.mode) end
  | ChildInvalid() => let val failed=context_limits_failed() in ot_context_rule_info(b,child.span,info.mode) end
fun rules{n:nat} .<n>. (left: int(n),b: !Buf,info: OtContextInfo,s: OtSpan,i: int,limits: OtContextLimits): OtContextLimits =
  if left = 0 then limits else let val p=pattern(b,info,ot_context_rule(b,s,i))
  in rules(left-1,b,info,s,iadd(i,1),merged(p,limits)) end
fun sets{n:nat} .<n>. (left: int(n),b: !Buf,info: OtContextInfo,i: int,limits: OtContextLimits): OtContextLimits =
  if left = 0 then limits else let val child=ot_context_set(b,info,i) in case+ child.kind of
    | ChildMissing() => sets(left-1,b,info,iadd(i,1),limits)
    | ChildInvalid() => let val failed=context_limits_failed() in limits end
    | ChildPresent() => sets(left-1,b,info,iadd(i,1),rules(airlock_nat(ot_u16(b,child.span,0)),b,info,child.span,0,limits)) end
implement ot_context_limits(b,p) = let val+ OtContextProgram(info,domain,c)=p
  val empty: OtContextLimits= @{back=0,input=0,look=0}
in case+ info.encoding of | ContextCoverages() => merged(info.pattern,empty)
  | ContextGlyphs() => sets(airlock_nat(info.setCount),b,info,0,empty)
  | ContextClasses() => sets(airlock_nat(info.setCount),b,info,0,empty) end
