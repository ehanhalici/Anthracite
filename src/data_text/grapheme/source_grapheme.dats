#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "mem.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/grapheme/grapheme.sats"
staload "data_text/unicode/unicode_db.sats"
staload "data_text/grapheme/source_grapheme.sats"
extern fun exhausted(): int = "mac#anth_die_int"
fun failed(): SourceBoundaries = let val n=exhausted()
in @{previous=n,lower=n,upper=n,next=n} end
fun finish(at: int,pos: int,lower: int,previous: int): SourceBoundaries =
  if ieq(at,lower) then @{previous=previous,lower=lower,upper=lower,next=pos}
  else @{previous=lower,lower=lower,upper=pos,next=pos}
fun walk{fuel:nat} .<fuel>. (fuel: int(fuel),db: !UnicodeDb,b: !Buf,n: int,at: int,
  pos: int,state: GraphemeState,lower: int,previous: int): SourceBoundaries =
  if ige(pos,n) then finish(at,n,if ieq(at,n) then n else lower,if ieq(at,n) then lower else previous)
  else if fuel = 0 then failed() else let
    val decoded=utf8_step(b,n,pos)
    val step=grapheme_step(db,state,decoded.value)
  in if step.boundary andalso igt(pos,at) then finish(at,pos,lower,previous)
    else walk(fuel-1,db,b,n,at,decoded.next,step.state,
      if step.boundary then pos else lower,if step.boundary then lower else previous) end
implement source_grapheme_query(db,b,n,at) =
  if ilt(n,0) orelse igt(n,buf_cap(b)) orelse igt(n,MAX_REC_FUEL)
    orelse ilt(at,0) orelse igt(at,n) then failed()
  else walk(airlock_nat(n),db,b,n,at,0,grapheme_initial(),0,0)
