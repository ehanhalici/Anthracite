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
fun ligate(run: GlyphRun(1),a: int,b: int,glyph: int,errors: &int >> _): GlyphRun(1) = let
  val nodes=run_test_indices(a,b)
  val run=run_test_take(glyph_run_ligate(run,nodes,2,glyph),run_test_updated,errors)
  val ()=buf_free(nodes)
in run end
fun rejected(run: GlyphRun(1),errors: &int >> _): GlyphRun(1) = let
  val reversed=run_test_indices(2,0) and duplicate=run_test_indices(0,0)
  val run=run_test_take(glyph_run_ligate(run,reversed,2,90),run_test_rejected,errors)
  val run=run_test_take(glyph_run_ligate(run,duplicate,2,90),run_test_rejected,errors)
  val ()=buf_free(reversed) and ()=buf_free(duplicate)
in run end
fun links(run: !GlyphRun(1)): int = let
  val meta=glyph_run_meta(run) val a=glyph_run_query(run,0) and mark=glyph_run_query(run,1)
  val removed=glyph_run_query(run,2)
  val dead=case+ removed.kind of | GlyphMissing() => true | GlyphPresent() => false
in if ieq(meta.live,5) andalso ieq(a.links.next,1) andalso ieq(mark.links.next,3) andalso dead
  andalso ieq(a.core.sourceStart,0) andalso ieq(a.core.sourceEnd,6) andalso ieq(a.core.components,2)
  andalso ieq(mark.core.cluster,a.core.cluster) andalso ieq(mark.core.sourceStart,2)
  andalso ieq(mark.core.sourceEnd,4) then 0 else 1 end
fun associations(run: !GlyphRun(1)): int = let
  val a=glyph_run_mark_association(run,1) and b=glyph_run_mark_association(run,5)
  val owner=glyph_run_query(run,0)
  val inner_mark=glyph_run_query(run,1) and outside_mark=glyph_run_query(run,5)
  val meta=glyph_run_meta(run)
in if a.found andalso b.found andalso ieq(a.owner,0) andalso ieq(b.owner,0)
  andalso ieq(a.component,1) andalso ieq(b.component,3) andalso ieq(a.components,4)
  andalso ieq(owner.core.sourceEnd,10) andalso ieq(meta.live,3)
  andalso ieq(inner_mark.core.cluster,0) andalso ieq(outside_mark.core.cluster,5) then 0 else 1 end
implement run_test_ligatures() = let var errors: int=0
  val run=glyph_run_substitute(run_test_nominal(8,6,errors))
  val run=rejected(run,errors) val run=ligate(run,0,2,90,errors)
  val ()=errors := iadd(errors,links(run))
  val run=run_test_take(glyph_run_bind_mark(run,1,0,1),run_test_updated,errors)
  val run=ligate(run,3,4,91,errors)
  val run=run_test_take(glyph_run_bind_mark(run,5,3,1),run_test_updated,errors)
  val run=ligate(run,0,3,92,errors)
  val ()=errors := iadd(errors,associations(run))
  val run=run_test_take(glyph_run_bind_mark(run,0,0,0),run_test_rejected,errors)
  val run=run_test_take(glyph_run_bind_mark(run,1,0,4),run_test_rejected,errors)
  val ()=glyph_run_dispose(run)
in errors end
