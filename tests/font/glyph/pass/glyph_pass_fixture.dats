#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "font/glyph/run/glyph_run_contracts.sats"
staload "font/glyph/pass/glyph_pass_contracts.sats"
extern fun pass_test_failed(): GlyphRun(1) = "mac#anth_die_box"
fun append{n:nat} .<n>. (n: int(n),run: GlyphRun(0),i: int,errors: &int >> _): GlyphRun(0) =
  if n = 0 then run else let
    val seed: GlyphSeed= @{glyph=iadd(10,imod(i,16)),scalar=1576,sourceStart=imul(i,2),
      sourceEnd=imul(iadd(i,1),2),cluster=i,mask=if ieq(imod(i,2),0) then 1u else 2u}
    val next=run_test_take(glyph_run_append(run,seed),run_test_updated,errors)
  in append(n-1,next,iadd(i,1),errors) end
implement pass_test_run(count) = case+ glyph_run_make(3,128,imul(count,2),iadd(count,4)) of
  | ~GlyphRunRejected(status) => pass_test_failed()
  | ~GlyphRunCreated(run) => let
    var errors: int=0
    val result=append(airlock_nat(count),run,0,errors)
  in if ieq(errors,0) then glyph_run_substitute(result)
    else let val ()=glyph_run_dispose(result) in pass_test_failed() end end
implement pass_test_take(result,visited,matches,errors) = let
  val+ ~GlyphPassResult(run,status,n,m)=result
  val applied: bool=case+ status of | GlyphPassApplied() => true | GlyphPassDomain() => false
    | GlyphPassReference() => false | GlyphPassCapacity() => false
  val ()=if applied andalso ieq(n,visited) andalso ieq(m,matches) then () else errors := iadd(errors,1)
in run end
