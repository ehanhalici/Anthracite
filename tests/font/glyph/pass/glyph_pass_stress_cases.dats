#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/pass/glyph_pass_single.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/opentype/substitution/gsub_single.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/glyph/pass/glyph_pass_contracts.sats"
fun inspect{n:nat} .<n>. (n: int(n),run: !GlyphRun(1),i: int,acc: int): int =
  if n = 0 then acc else let
    val v=glyph_run_query(run,i)
    val ok=ieq(v.core.glyph,iadd(11,imod(i,16))) andalso ieq(v.core.sourceStart,imul(i,2))
      andalso ieq(v.core.sourceEnd,imul(iadd(i,1),2)) andalso ieq(v.core.cluster,i)
  in inspect(n-1,run,iadd(i,1),iadd(acc,if ok then 0 else 1)) end
implement pass_test_stress() = let
  val b=ot_fixture_words("0001 0006 0001 0002 0001 000A 0019 0000")
  val errors: int=case+ gsub_single_parse(b,ot_fixture_span(b),128) of
  | ~SingleRejected(e) => 1 | ~SingleAccepted(t) => let
    var e: int=0
    val run=pass_test_take(glyph_pass_single(b,t,pass_test_run(WORD16_SIGN_BIT),@{kind=GlyphAll(),mask=0u}),WORD16_SIGN_BIT,WORD16_SIGN_BIT,e)
    val extra=inspect(WORD16_SIGN_BIT,run,0,0)
    val ()=glyph_run_dispose(run) and ()=gsub_single_dispose(t)
  in e+extra end
  val ()=buf_free(b)
in errors end
