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
staload "data_font/ot_context_match_work.sats"
staload "data_font/ot_cov_cache.sats"
implement ot_context_missing(domain) =
  @{domain=domain,matched=false,inputCount=0,actions= @{offset=0,length=0},actionCount=0,rule=0}
implement ot_context_result(domain,p,rule) = @{domain=domain,matched=true,inputCount=p.inputCount,
  actions= @{offset=iadd(p.span.offset,p.actionsAt),length=imul(p.actionCount,4)},actionCount=p.actionCount,rule=rule}
implement ot_context_pattern_fits(p,count,start) =
  ige(start,p.backCount) andalso ile(p.inputCount,isub(count,start))
    andalso ile(p.lookCount,isub(isub(count,start),p.inputCount))
implement ot_context_pattern_fits_input(p,count,start,inputLimit) =
  ile(p.inputCount,inputLimit) andalso ot_context_pattern_fits(p,count,start)
implement ot_context_action(b,result,index) = let
  val at=imul(airlock_below(index,airlock_pos(result.actionCount)),4)
in @{domain=result.domain,position=ot_u16(b,result.actions,at),lookup=ot_u16(b,result.actions,iadd(at,2))} end
implement ot_context_dispose(program) = let val+ ~OtContextProgram(info,domain,cache)=program in
  ot_cov_cache_dispose(cache) end
