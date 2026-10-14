#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8.sats"
staload "data_text/text_source.sats"
staload "data_text/text_fields.sats"
staload "scalar_fixture.sats"
extern fun scalar_fixture_exhausted(): int = "mac#anth_die_int"

fun cps {n:nat} .<n>. (n: int(n), source: !Buf, p: int, finish: int, values: !Buf, count: int): int =
  if ige(text_skip_space(source,p,finish),finish) then count else if n = 0 then scalar_fixture_exhausted() else let
    val start = text_skip_space(source,p,finish)
    var position: int = start
    val cp = text_hex(source,position,finish)
    val () = if ile(position,start) then let val stop = scalar_fixture_exhausted() in () end else ()
    val () = buf_set32(values,count,cp)
  in cps(n-1,source,position,finish,values,iadd(count,1)) end

implement scalar_fixture_parse(source,start,finish) = let
  val capacity = iadd(isub(finish,start),1)
  val values = buf_make(imul(capacity,4))
  val starts = buf_make(imul(capacity,4))
  val ends = buf_make(imul(capacity,4))
  val count = cps(airlock_nat(capacity),source,start,finish,values,0)
in ScalarText(values,starts,ends,count,0) end

implement scalar_fixture_column(source,start,finish,column) = let
  val first = text_field(source,start,finish,column)
  val last = text_find_byte(source,first,finish,59)
in scalar_fixture_parse(source,first,last) end

fun differences {n:nat} .<n>. (n: int(n), actual: !ScalarText, expected: !ScalarText, i: int, errors: int): int =
  if n = 0 then errors else let
    val same = ieq(scalar_value(actual,i),scalar_value(expected,i))
  in differences(n-1,actual,expected,iadd(i,1),iadd(errors,if same then 0 else 1)) end

implement scalar_fixture_differences(actual,expected) =
  if ine(scalar_count(actual),scalar_count(expected)) then 1
  else differences(airlock_nat(scalar_count(actual)),actual,expected,0,0)

