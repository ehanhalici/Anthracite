#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/source/text_source.sats"
staload "data_text/utf8/utf8.sats"
staload "text/line_break/line_fixture.sats"

extern fun fixture_exhausted(): int = "mac#anth_die_int"

fun mark(source: !Buf,p: int,expected: !Buf,index: int): void = let
  val marker = buf_get(source,iadd(p,1))
in if ine(buf_get(source,p),195) orelse not(ieq(marker,183) orelse ieq(marker,151))
  then let val code=fixture_exhausted() in seen_int(code) end
  else buf_set(expected,index,if ieq(marker,183) then 1 else 0) end

fun parse {fuel:nat} .<fuel>. (fuel: int(fuel),source: !Buf,pos: int,en: int,
  cps: !Buf,starts: !Buf,ends: !Buf,expected: !Buf,count: int): int =
  if fuel = 0 then fixture_exhausted() else let
    val p = text_skip_space(source,pos,en)
    val () = mark(source,p,expected,count)
    var next: int = text_skip_space(source,iadd(p,2),en)
    val token_start = next
  in if ige(next,en) orelse ieq(buf_get(source,next),35) then count else let
    val cp = text_hex(source,next,en)
    val () = buf_set32(cps,count,cp)
    val () = buf_set32(starts,count,token_start)
    val () = buf_set32(ends,count,next)
  in parse(fuel-1,source,next,en,cps,starts,ends,expected,iadd(count,1)) end end

implement line_fixture_parse(source,start,en) = let
  val capacity = iadd(isub(en,start),1)
  val cps = buf_make(imul(capacity,4))
  val starts = buf_make(imul(capacity,4))
  val ends = buf_make(imul(capacity,4))
  val expected = buf_make(capacity)
  val count = parse(airlock_nat(capacity),source,start,en,cps,starts,ends,expected,0)
in LineFixture(ScalarText(cps,starts,ends,count,0),expected) end
