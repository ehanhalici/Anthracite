#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run.sats"
staload "glyph_run_contracts.sats"
fun check_source(run: !GlyphRun(1),node: int,glyph: int,previous: int,next: int): int = let
  val v=glyph_run_query(run,node)
  val found=case+ v.kind of | GlyphMissing() => false | GlyphPresent() => true
in if found andalso ieq(v.core.glyph,glyph) andalso ieq(v.links.previous,previous) andalso ieq(v.links.next,next)
  andalso ieq(v.core.sourceStart,0) andalso ieq(v.core.sourceEnd,2) andalso ieq(v.core.cluster,0)
  andalso ieq(v.core.scalar,1576) andalso v.core.mask = 3u then 0 else 1 end
fun single(run: GlyphRun(1),errors: &int >> _): GlyphRun(1) = let
  val run=run_test_take(glyph_run_single(run,0,0),run_test_updated,errors)
  val v=glyph_run_query(run,0)
  val ()=if ieq(v.core.glyph,0) then () else errors := iadd(errors,1)
in run end
fun expanded(run: GlyphRun(1),errors: &int >> _): GlyphRun(1) = let
  val output=buf_make(12)
  val ()=buf_set32(output,0,3) and ()=buf_set32(output,1,4) and ()=buf_set32(output,2,5)
  val run=run_test_take(glyph_run_multiple(run,0,output,3),run_test_updated,errors)
  val checked=check_source(run,0,3,~1,2)+check_source(run,2,4,0,3)+check_source(run,3,5,2,1)
  val meta=glyph_run_meta(run)
  val ()=errors := iadd(errors,iadd(checked,if ieq(meta.used,4) andalso ieq(meta.live,4) andalso ieq(meta.tail,1) then 0 else 1))
  val ()=buf_set32(output,0,77) and ()=buf_set32(output,1,128)
  val run=run_test_take(glyph_run_multiple(run,0,output,3),run_test_rejected,errors)
  val ()=errors := iadd(errors,check_source(run,0,3,~1,2))
  val ()=buf_free(output)
in run end
fun rejected(run: GlyphRun(1),errors: &int >> _): GlyphRun(1) = let
  val run=run_test_take(glyph_run_single(run,0,128),run_test_rejected,errors)
  val run=run_test_take(glyph_run_single(run,99,5),run_test_rejected,errors)
  val run=run_test_take(glyph_run_reserve(run,~1),run_test_rejected,errors)
  val missing=glyph_run_query(run,~1)
  val ()=case+ missing.kind of | GlyphMissing() => () | GlyphPresent() => errors := iadd(errors,1)
in run end
fun capacity(): int = let var errors: int=0
  val run=glyph_run_substitute(run_test_nominal(2,2,errors))
  val output=buf_make(8)
  val ()=buf_set32(output,0,77) and ()=buf_set32(output,1,78)
  val run=run_test_take(glyph_run_multiple(run,0,output,2),run_test_rejected,errors)
  val run=run_test_take(glyph_run_multiple(run,0,output,0),run_test_rejected,errors)
  val run=run_test_take(glyph_run_multiple(run,0,output,2147483647),run_test_rejected,errors)
  val v=glyph_run_query(run,0) val meta=glyph_run_meta(run)
  val ()=if ieq(v.core.glyph,10) andalso ieq(v.links.next,1) andalso ieq(meta.used,2)
    andalso ieq(meta.live,2) then () else errors := iadd(errors,1)
  val ()=buf_free(output) and ()=glyph_run_dispose(run)
in errors end
implement run_test_basic() = let var errors: int=0
  val run=run_test_nominal(2,2,errors)
  val run=run_test_take(glyph_run_reserve(run,2),run_test_unchanged,errors)
  val run=run_test_take(glyph_run_reserve(run,8),run_test_updated,errors)
  val run=glyph_run_substitute(run)
  val run=expanded(single(run,errors),errors)
  val run=rejected(run,errors)
  val ()=glyph_run_dispose(run)
in iadd(errors,capacity()) end
