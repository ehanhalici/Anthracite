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
staload "opentype_fixture.sats"
staload "glyph_pass_contracts.sats"
fun inspect{n:nat} .<n>. (n: int(n),run: !GlyphRun(1),i: int,selection: GlyphSelection,delta: int): int =
  if n = 0 then 0 else let
    val v=glyph_run_query(run,i)
    val d: int=case+ selection.kind of
      | GlyphAll() => delta | GlyphMasked() => if ieq(imod(i,2),1) then delta else 0
    val ok=ieq(v.core.glyph,iadd(iadd(10,i),d)) andalso ieq(v.core.sourceStart,imul(i,2))
      andalso ieq(v.core.sourceEnd,imul(iadd(i,1),2)) andalso ieq(v.core.cluster,i)
  in iadd(if ok then 0 else 1,inspect(n-1,run,iadd(i,1),selection,delta)) end
fun apply(b: !Buf,t: !GsubSingle,selection: GlyphSelection,matches: int): int = let
  var errors: int=0
  val first=pass_test_take(glyph_pass_single(b,t,pass_test_run(6),selection),6,matches,errors)
  val ()=errors := iadd(errors,inspect(6,first,0,selection,1))
  val second=pass_test_take(glyph_pass_single(b,t,first,selection),6,matches,errors)
  val ()=errors := iadd(errors,inspect(6,second,0,selection,2))
  val ()=glyph_run_dispose(second)
  val empty=pass_test_take(glyph_pass_single(b,t,pass_test_run(0),selection),0,0,errors)
  val ()=glyph_run_dispose(empty)
in errors end
fun disabled(b: !Buf,t: !GsubSingle): int = let
  var errors: int=0
  val run=pass_test_take(glyph_pass_single(b,t,pass_test_run(6),@{kind=GlyphMasked(),mask=0u}),6,0,errors)
  val ()=errors := iadd(errors,inspect(6,run,0,@{kind=GlyphAll(),mask=0u},0))
  val ()=glyph_run_dispose(run)
in errors end
fun mismatch(b: !Buf): int = case+ gsub_single_parse(b,ot_fixture_span(b),129) of
  | ~SingleRejected(e) => 1 | ~SingleAccepted(t) => let
    val+ ~GlyphPassResult(run,status,n,m)=glyph_pass_single(b,t,pass_test_run(6),@{kind=GlyphAll(),mask=0u})
    val rejected: bool=case+ status of | GlyphPassApplied() => false | GlyphPassDomain() => true
      | GlyphPassReference() => false | GlyphPassCapacity() => false
    val errors=inspect(6,run,0,@{kind=GlyphAll(),mask=0u},0)
    val ()=glyph_run_dispose(run) and ()=gsub_single_dispose(t)
  in iadd(errors,if rejected andalso ieq(n,0) andalso ieq(m,0) then 0 else 1) end
fun identity(): int = let
  val b=ot_fixture_words("0002 000A 0002 0000 000B 0001 0002 000A 000B")
  val errors: int=case+ gsub_single_parse(b,ot_fixture_span(b),128) of
  | ~SingleRejected(e) => 1 | ~SingleAccepted(t) => let
    var e: int=0
    val run=pass_test_take(glyph_pass_single(b,t,pass_test_run(3),@{kind=GlyphAll(),mask=0u}),3,2,e)
    val a=glyph_run_query(run,0) and v=glyph_run_query(run,1) and c=glyph_run_query(run,2)
    val ok=ieq(a.core.glyph,0) andalso ieq(v.core.glyph,11) andalso ieq(c.core.glyph,12)
    val ()=glyph_run_dispose(run) and ()=gsub_single_dispose(t)
  in iadd(e,if ok then 0 else 1) end
  val ()=buf_free(b)
in errors end
implement pass_test_basic() = let
  val b=ot_fixture_words("0001 0006 0001 0002 0001 000A 0019 0000")
  val errors: int=case+ gsub_single_parse(b,ot_fixture_span(b),128) of
  | ~SingleRejected(e) => 1 | ~SingleAccepted(t) => let
    val e=apply(b,t,@{kind=GlyphAll(),mask=0u},6)+apply(b,t,@{kind=GlyphMasked(),mask=2u},3)+disabled(b,t)
    val ()=gsub_single_dispose(t)
  in e end
  val rejected=mismatch(b)
  val ()=buf_free(b)
in iadd(errors,iadd(rejected,identity())) end
