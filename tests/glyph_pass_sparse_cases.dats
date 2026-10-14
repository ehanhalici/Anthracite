#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_pass_single.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/gsub_single.sats"
staload "glyph_run_contracts.sats"
staload "glyph_pass_contracts.sats"
staload "opentype_fixture.sats"
fun sparse(errors: &int >> _): GlyphRun(1) = let
  val outputs=run_test_indices(20,21)
  val expanded=run_test_take(glyph_run_multiple(pass_test_run(4),0,outputs,2),run_test_updated,errors)
  val nodes=run_test_indices(1,3)
  val run=run_test_take(glyph_run_ligate(expanded,nodes,2,22),run_test_updated,errors)
  val ()=buf_free(outputs) and ()=buf_free(nodes)
in run end
fun inspect(run: !GlyphRun(1)): int = let
  val a=glyph_run_query(run,0) and b=glyph_run_query(run,4)
  val c=glyph_run_query(run,1) and d=glyph_run_query(run,2)
  val dead=glyph_run_query(run,3)
  val removed: bool=case+ dead.kind of | GlyphMissing() => true | GlyphPresent() => false
  val owner: bool=case+ c.core.association of
    | LigatureOwner() => true | Unassociated() => false | LigatureMark() => false | LigatureForward() => false
  val ok=removed andalso owner andalso ieq(a.core.glyph,21) andalso ieq(b.core.glyph,22)
    andalso ieq(c.core.glyph,23) andalso ieq(d.core.glyph,13) andalso ieq(c.core.components,2)
    andalso ieq(c.core.sourceStart,2) andalso ieq(c.core.sourceEnd,8) andalso ieq(c.core.cluster,1)
    andalso ieq(b.links.next,1) andalso ieq(d.links.next,~1)
in if ok then 0 else 1 end
implement pass_test_sparse() = let
  val b=ot_fixture_words("0001 0006 0001 0002 0001 000A 0019 0000")
  val errors: int=case+ gsub_single_parse(b,ot_fixture_span(b),128) of
  | ~SingleRejected(e) => 1 | ~SingleAccepted(t) => let
    var e: int=0
    val run=pass_test_take(glyph_pass_single(b,t,sparse(e),@{kind=GlyphAll(),mask=0u}),4,4,e)
    val extra=inspect(run)
    val ()=glyph_run_dispose(run) and ()=gsub_single_dispose(t)
  in e+extra end
  val ()=buf_free(b)
in errors end
