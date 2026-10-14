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

fun parse_cps {n:nat} .<n>. (n: int(n), source: !Buf, p: int, en: int, output: !Buf, count: int): int =
  if ige(p,en) then count else if n = 0 then fixture_parse_exhausted() else let
    var next: int = text_skip_space(source,p,en)
  in if ige(next,en) then count else let
      val cp = text_hex(source,next,en)
      val () = if ilt(cp,0) then let val stop = fixture_parse_exhausted() in () end else ()
      val () = buf_set32(output,count,cp)
    in parse_cps(n-1,source,text_skip_space(source,next,en),en,output,iadd(count,1)) end end

implement bidi_fixture_text(source,start,finish) = let
  val capacity = iadd(isub(finish,start),1)
  val cps = buf_make(imul(capacity,4))
  val starts = buf_make(imul(capacity,4))
  val ends = buf_make(imul(capacity,4))
  val count = parse_cps(airlock_nat(capacity),source,start,finish,cps,0)
in ScalarText(cps,starts,ends,count,0) end

fun digits {n:nat} .<n>. (n: int(n), source: !Buf, p: &int >> _, finish: int, value: int): int =
  if ige(p,finish) then value else if n = 0 then fixture_parse_exhausted() else let
    val byte = buf_get(source,p)
  in if ilt(byte,48) orelse igt(byte,57) then value else let
      val () = p := iadd(p,1)
    in digits(n-1,source,p,finish,iadd(imul(value,10),isub(byte,48))) end end

implement bidi_fixture_decimal(source,position,finish) = let
  val () = position := text_skip_space(source,position,finish)
in digits(airlock_nat(iadd(isub(finish,position),1)),source,position,finish,0) end

implement bidi_fixture_fields(source,start,finish) = let
  val first = text_find_byte(source,start,finish,59)
  val second = text_find_byte(source,iadd(first,1),finish,59)
  val third = text_find_byte(source,iadd(second,1),finish,59)
  val fourth = text_find_byte(source,iadd(third,1),finish,59)
in @{direction=iadd(first,1),base=iadd(second,1),levels=iadd(third,1),order=iadd(fourth,1)} end

