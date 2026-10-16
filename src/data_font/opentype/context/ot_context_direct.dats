#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/opentype/context/ot_context_header.sats"
fun accepted(s: OtSpan,p: OtContextPattern,glyphs: int,lookups: int,mode: OtContextMode): OtContextHeaderRead = let
  val floor=iadd(p.actionsAt,imul(p.actionCount,4))
  var info: OtContextInfo=ot_context_info(s,mode,ContextCoverages(),0,0,floor,glyphs,lookups)
  val ()=info.pattern := p
in ContextHeaderAccepted(info) end
fun plain(b: !Buf,s: OtSpan,glyphs: int,lookups: int): OtContextHeaderRead =
  if ilt(s.length,6) then ContextHeaderRejected(ot_error(OtBounds(),s)) else let
    val input=ot_u16(b,s,2) and count=ot_u16(b,s,4)
    val at=iadd(6,imul(input,2))
  in if ieq(input,0) then ContextHeaderRejected(ot_error(OtFormat(),s))
    else if not(ot_rows_fit(s,6,input,2)) orelse not(ot_rows_fit(s,at,count,4))
      then ContextHeaderRejected(ot_error(OtBounds(),s))
    else accepted(s,@{span=s,backAt=0,backCount=0,inputAt=6,inputCount=input,
      lookAt=0,lookCount=0,actionsAt=at,actionCount=count},glyphs,lookups,ContextPlain()) end
fun actions(b: !Buf,s: OtSpan,p: OtContextPattern,glyphs: int,lookups: int): OtContextHeaderRead =
  if not(ot_rows_fit(s,p.actionsAt,p.actionCount,4)) then ContextHeaderRejected(ot_error(OtBounds(),s))
  else accepted(s,p,glyphs,lookups,ContextChained())
fun look(b: !Buf,s: OtSpan,back: int,inputAt: int,inputCount: int,
  glyphs: int,lookups: int): OtContextHeaderRead = let
  val lookAt=iadd(iadd(inputAt,imul(inputCount,2)),2)
  val lookCount=ot_u16(b,s,isub(lookAt,2))
  val actionsAt=iadd(iadd(lookAt,imul(lookCount,2)),2)
in if not(ot_rows_fit(s,iadd(lookAt,2),lookCount,2)) then ContextHeaderRejected(ot_error(OtBounds(),s))
  else actions(b,s,@{span=s,backAt=4,backCount=back,inputAt=inputAt,inputCount=inputCount,
    lookAt=lookAt,lookCount=lookCount,actionsAt=actionsAt,actionCount=ot_u16(b,s,isub(actionsAt,2))},glyphs,lookups) end
fun input(b: !Buf,s: OtSpan,back: int,glyphs: int,lookups: int): OtContextHeaderRead = let
  val at=iadd(6,imul(back,2))
  val count=ot_u16(b,s,isub(at,2))
in if ieq(count,0) then ContextHeaderRejected(ot_error(OtFormat(),s))
  else if not(ot_rows_fit(s,iadd(at,2),count,2)) then ContextHeaderRejected(ot_error(OtBounds(),s))
  else look(b,s,back,at,count,glyphs,lookups) end
fun chained(b: !Buf,s: OtSpan,glyphs: int,lookups: int): OtContextHeaderRead =
  if ilt(s.length,4) then ContextHeaderRejected(ot_error(OtBounds(),s)) else let val count=ot_u16(b,s,2) in
    if not(ot_rows_fit(s,6,count,2)) then ContextHeaderRejected(ot_error(OtBounds(),s))
    else input(b,s,count,glyphs,lookups) end
implement ot_context_direct(b,s,glyphs,lookups,mode) = case+ mode of
  | ContextPlain() => plain(b,s,glyphs,lookups) | ContextChained() => chained(b,s,glyphs,lookups)
