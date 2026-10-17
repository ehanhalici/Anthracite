#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "font/glyph/run/glyph_run_contracts.sats"
fun singles {n:nat} .<n>. (n: int(n),run: GlyphRun(1),index: int,errors: &int >> _): GlyphRun(1) =
  if n = 0 then run else let
    val next=run_test_take(glyph_run_single(run,index,7),run_test_updated,errors)
  in singles(n-1,next,iadd(index,1),errors) end
fun traversal {n:nat} .<n>. (n: int(n),run: !GlyphRun(1),node: int,index: int,errors: int): int =
  if n = 0 then iadd(errors,if ieq(node,~1) then 0 else 1) else let
    val v=glyph_run_query(run,node)
    val found=case+ v.kind of | GlyphMissing() => false | GlyphPresent() => true
    val ok=found andalso ieq(v.core.glyph,7) andalso ieq(v.core.sourceStart,imul(index,2))
      andalso ieq(v.core.sourceEnd,imul(iadd(index,1),2)) andalso ieq(v.core.cluster,index)
  in traversal(n-1,run,v.links.next,iadd(index,1),iadd(errors,if ok then 0 else 1)) end
fun scalar_edits(): int = let var errors: int=0
  val run=glyph_run_substitute(run_test_nominal(WORD16_SIGN_BIT,WORD16_SIGN_BIT,errors))
  val run=singles(WORD16_SIGN_BIT,run,0,errors)
  val ()=errors := iadd(errors,traversal(WORD16_SIGN_BIT,run,0,0,0))
  val ()=glyph_run_dispose(run)
in errors end
fun shared {n:nat} .<n>. (n: int(n),run: !GlyphRun(1),node: int,errors: int): int =
  if n = 0 then iadd(errors,if ieq(node,~1) then 0 else 1) else let
    val v=glyph_run_query(run,node)
    val found=case+ v.kind of | GlyphMissing() => false | GlyphPresent() => true
    val ok=found andalso ieq(v.core.glyph,0) andalso ieq(v.core.sourceStart,0)
      andalso ieq(v.core.sourceEnd,2) andalso ieq(v.core.cluster,7)
  in shared(n-1,run,v.links.next,iadd(errors,if ok then 0 else 1)) end
fun expand(run: GlyphRun(0),errors: &int >> _): GlyphRun(1) = let
  val seed: GlyphSeed= @{glyph=1,scalar=1576,sourceStart=0,sourceEnd=2,cluster=7,mask=3u}
  val run=run_test_take(glyph_run_append(run,seed),run_test_updated,errors)
  val run=glyph_run_substitute(run)
  val output=buf_make(262140)
  val run=run_test_take(glyph_run_multiple(run,0,output,WORD16_MAX_VALUE),run_test_updated,errors)
  val ()=buf_free(output)
in run end
fun expanded(): int = case+ glyph_run_make(3,WORD16_MAX_VALUE,2,WORD16_MAX_VALUE) of
  | ~GlyphRunRejected(status) => 1 | ~GlyphRunCreated(run) => let var errors: int=0
    val run=expand(run,errors)
    val ()=errors := iadd(errors,shared(WORD16_MAX_VALUE,run,0,0))
    val ()=glyph_run_dispose(run)
  in errors end
implement run_test_stress() = scalar_edits()+expanded()
