#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/source/text_source.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/unicode/property_symbols.sats"
staload "data_text/bidi/bidi_bracket_data.sats"
staload "text/bidi/bidi_fixture.sats"
staload "text/bidi/bidi_class_fixture.sats"
extern fun class_fixture_exhausted(): int = "mac#anth_die_int"

fun class_values {n:nat} .<n>. (
  n: int(n), source: !Buf, p: int, finish: int, original: !Buf, current: !Buf, matching: !Buf, count: int
): int = if ige(text_skip_space(source,p,finish),finish) then count
  else if n = 0 then class_fixture_exhausted() else let
    val start = text_skip_space(source,p,finish)
    val en = text_find_byte(source,start,finish,32)
    val code = property_symbol_of(BidiProperty(),source,start,en)
    val () = if ilt(code,0) then let val stop = class_fixture_exhausted() in () end else ()
    val () = buf_set(original,count,code)
    val () = buf_set(current,count,code)
    val () = buf_set32(matching,count,~1)
  in class_values(n-1,source,en,finish,original,current,matching,iadd(count,1)) end

implement bidi_class_fixture(source,start,finish) = let
  val capacity = iadd(isub(finish,start),1)
  val original = buf_make(capacity)
  val current = buf_make(capacity)
  val levels = buf_make(capacity)
  val matching = buf_make(imul(capacity,4))
  val count = class_values(airlock_nat(capacity),source,start,finish,original,current,matching,0)
  val values = buf_make(imul(count,4))
  val starts = buf_make(imul(count,4))
  val ends = buf_make(imul(count,4))
  val text = ScalarText(values,starts,ends,count,0)
  val work = BidiWork(original,current,levels,matching,count,0)
in BidiClassFixture(text,work) end
