#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi_types.sats"
staload "data_text/utf8.sats"
staload "data_text/text_source.sats"
staload "data_text/bidi_line.sats"
staload "bidi_fixture.sats"
extern fun fixture_parse_exhausted(): int = "mac#anth_die_int"

fun levels {n:nat} .<n>. (
  n: int(n), source: !Buf, p: int, finish: int, work: !BidiWork, i: int, errors: int
): int = if ige(text_skip_space(source,p,finish),finish) then
    iadd(errors,if ieq(i,bidi_count(work)) then 0 else 1)
  else if n = 0 then fixture_parse_exhausted() else let
    var next: int = text_skip_space(source,p,finish)
    val removed = ieq(buf_get(source,next),120)
    val expected = if removed then let val () = next := iadd(next,1) in ~1 end
      else bidi_fixture_decimal(source,next,finish)
    val error = if removed then 0 else if ieq(expected,bidi_level(work,i)) then 0 else 1
  in levels(n-1,source,next,finish,work,iadd(i,1),iadd(errors,error)) end

implement bidi_fixture_check_levels(source,start,finish,work) =
  levels(airlock_nat(iadd(isub(finish,start),1)),source,start,finish,work,0,0)

fun indices {n:nat} .<n>. (
  n: int(n), source: !Buf, p: int, finish: int, order: !BidiOrder, i: int, errors: int
): int = if ige(text_skip_space(source,p,finish),finish) then
    iadd(errors,if ieq(i,bidi_order_count(order)) then 0 else 1)
  else if n = 0 then fixture_parse_exhausted() else let
    var next: int = p
    val expected = bidi_fixture_decimal(source,next,finish)
    val error = if ilt(i,bidi_order_count(order)) andalso ieq(expected,bidi_order_index(order,i)) then 0 else 1
  in indices(n-1,source,next,finish,order,iadd(i,1),iadd(errors,error)) end

implement bidi_fixture_check_order(source,start,finish,order) =
  indices(airlock_nat(iadd(isub(finish,start),1)),source,start,finish,order,0,0)

