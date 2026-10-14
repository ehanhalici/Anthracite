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
staload "opentype_fixture.sats"
staload "arabic_join_contracts.sats"
fun check{n:nat} .<n>. (n: int(n),run: !GlyphRun(1),text: !ScalarText,expected: !Buf,i: int,acc: int): int =
  if n = 0 then acc else let
    val v=glyph_run_query(run,i)
    val mask=2147483648u lor u_of(ot_fixture_read16(expected,imul(i,2)))
    val ok=v.core.mask = mask andalso ieq(v.core.glyph,iadd(10,imod(i,16)))
      andalso ieq(v.core.scalar,scalar_value(text,i)) andalso ieq(v.core.sourceStart,scalar_start(text,i))
      andalso ieq(v.core.sourceEnd,scalar_end(text,i)) andalso ieq(v.core.cluster,i)
  in check(n-1,run,text,expected,iadd(i,1),iadd(acc,if ok then 0 else 1)) end
implement arabic_test_check(run,text,expected) =
  if ine(isub(buf_len(expected),8),imul(scalar_count(text),2)) then 1
  else check(airlock_nat(scalar_count(text)),run,text,expected,0,0)
fun decoded(map: !PropertyMap(3),plan: !ArabicMaskPlan,text: ScalarText,words: string,context: ArabicContext): int = let
  val expected=ot_fixture_words(words)
  val run=glyph_arabic_prepare(map,plan,context,arabic_test_nominal(text))
  val errors=iadd(arabic_test_check(run,text,expected),if ieq(scalar_errors(text),0) then 0 else 1)
  val ()=glyph_run_dispose(run) and ()=scalar_dispose(text) and ()=buf_free(expected)
in errors end
implement arabic_test_sequence(map,plan,source,expected,context) = let
  val b=arabic_test_bytes(source)
  val errors: int=case+ text_decode(b,buf_len(b)) of
    | ~InvalidTextSpan() => 1 | ~DecodedText(text) => decoded(map,plan,text,expected,context)
  val ()=buf_free(b)
in errors end
