#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/ot_context_pattern.sats"
fun actions(b: !Buf,s: OtSpan,mode: OtContextMode): OtContextPatternRead = let
  val p=ot_context_rule_info(b,s,mode)
in if not(ot_rows_fit(s,p.actionsAt,p.actionCount,4)) then PatternRejected(ot_error(OtBounds(),s))
  else PatternAccepted(p) end
fun plain(b: !Buf,s: OtSpan): OtContextPatternRead =
  if ilt(s.length,4) then PatternRejected(ot_error(OtBounds(),s)) else let val count=ot_u16(b,s,0) in
    if ieq(count,0) then PatternRejected(ot_error(OtFormat(),s))
    else if not(ot_rows_fit(s,4,isub(count,1),2)) then PatternRejected(ot_error(OtBounds(),s))
    else actions(b,s,ContextPlain()) end
fun lookahead(b: !Buf,s: OtSpan,at: int): OtContextPatternRead = let
  val count=ot_u16(b,s,isub(at,2))
in if not(ot_rows_fit(s,iadd(at,2),count,2)) then PatternRejected(ot_error(OtBounds(),s))
  else actions(b,s,ContextChained()) end
fun input(b: !Buf,s: OtSpan,at: int): OtContextPatternRead = let
  val count=ot_u16(b,s,isub(at,2))
in if ieq(count,0) then PatternRejected(ot_error(OtFormat(),s))
  else if not(ot_rows_fit(s,iadd(at,2),isub(count,1),2)) then PatternRejected(ot_error(OtBounds(),s))
  else lookahead(b,s,iadd(iadd(at,imul(isub(count,1),2)),2)) end
fun chained(b: !Buf,s: OtSpan): OtContextPatternRead =
  if ilt(s.length,2) then PatternRejected(ot_error(OtBounds(),s)) else let val count=ot_u16(b,s,0) in
    if not(ot_rows_fit(s,4,count,2)) then PatternRejected(ot_error(OtBounds(),s))
    else input(b,s,iadd(4,imul(count,2))) end
implement ot_context_rule_parse(b,s,mode) = case+ mode of
  | ContextPlain() => plain(b,s) | ContextChained() => chained(b,s)
