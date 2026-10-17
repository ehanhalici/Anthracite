#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/opentype/context/ot_context_pattern.sats"
fun plain(b: !Buf,s: OtSpan): OtContextPattern = let
  val count=ot_u16(b,s,0)
  val actions=iadd(4,imul(isub(count,1),2))
in @{span=s,backAt=0,backCount=0,inputAt=4,inputCount=count,
  lookAt=0,lookCount=0,actionsAt=actions,actionCount=ot_u16(b,s,2)} end
fun chained(b: !Buf,s: OtSpan): OtContextPattern = let
  val back=ot_u16(b,s,0)
  val inputAt=iadd(4,imul(back,2))
  val inputCount=ot_u16(b,s,isub(inputAt,2))
  val lookAt=iadd(iadd(inputAt,imul(isub(inputCount,1),2)),2)
  val lookCount=ot_u16(b,s,isub(lookAt,2))
  val actionsAt=iadd(iadd(lookAt,imul(lookCount,2)),2)
in @{span=s,backAt=2,backCount=back,inputAt=inputAt,inputCount=inputCount,
  lookAt=lookAt,lookCount=lookCount,actionsAt=actionsAt,actionCount=ot_u16(b,s,isub(actionsAt,2))} end
implement ot_context_rule_info(b,s,mode) = case+ mode of
  | ContextPlain() => plain(b,s) | ContextChained() => chained(b,s)
