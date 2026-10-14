#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8.sats"
staload "data_text/unicode_property.sats"
staload "data_text/arabic_join_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_arabic.sats"
staload "arabic_join_contracts.sats"
fun one(map: !PropertyMap(3),plan: !ArabicMaskPlan,index: int): int = let
  val source=arabic_test_rule_source(index) and expected=arabic_test_rule_expected(index)
  val errors: int=case+ text_decode(source,buf_len(source)) of
    | ~InvalidTextSpan() => 1 | ~DecodedText(text) => let
      val run=glyph_arabic_prepare(map,plan,@{before=BoundaryNone(),after=BoundaryNone()},arabic_test_nominal(text))
      val e=arabic_test_check(run,text,expected)
      val ()=glyph_run_dispose(run) and ()=scalar_dispose(text)
    in e end
  val ()=buf_free(source) and ()=buf_free(expected)
in errors end
fun cases{n:nat} .<n>. (n: int(n),map: !PropertyMap(3),plan: !ArabicMaskPlan,index: int): int =
  if n = 0 then 0 else iadd(one(map,plan,index),cases(n-1,map,plan,iadd(index,1)))
implement arabic_test_rules(map,plan) = cases(216,map,plan,0)
