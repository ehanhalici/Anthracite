#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/arabic/joining/arabic_join_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/core/glyph_arabic.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "text/arabic/joining/arabic_join_contracts.sats"
fun fill{n:nat} .<n>. (n: int(n),source: !Buf,expected: !Buf,i: int): void =
  if n = 0 then () else let
    val edge=ieq(i,0) orelse ieq(i,32767)
    val ()=buf_set(source,imul(i,2),if edge then 216 else 217)
    val ()=buf_set(source,iadd(imul(i,2),1),if edge then 168 else 142)
    val ()=ot_fixture_put16(expected,imul(i,2),if ieq(i,0) then 1 else if ieq(i,32767) then 4 else 0)
  in fill(n-1,source,expected,iadd(i,1)) end
fun check(map: !PropertyMap(3),plan: !ArabicMaskPlan,source: !Buf,expected: !Buf): int =
  case+ text_decode(source,buf_len(source)) of
  | ~InvalidTextSpan() => 1 | ~DecodedText(text) => let
    val run=glyph_arabic_prepare(map,plan,@{before=BoundaryNone(),after=BoundaryNone()},arabic_test_nominal(text))
    val errors=arabic_test_check(run,text,expected)
    val ()=glyph_run_dispose(run) and ()=scalar_dispose(text)
  in errors end
implement arabic_test_stress(map,plan) = let
  val source=buf_make(WORD16_MODULUS) and expected=buf_make(65544)
  val ()=fill(WORD16_SIGN_BIT,source,expected,0)
  val ()=buf_set_len(source,WORD16_MODULUS) and ()=buf_set_len(expected,65544)
  val errors=check(map,plan,source,expected)
  val ()=buf_free(source) and ()=buf_free(expected)
in errors end
