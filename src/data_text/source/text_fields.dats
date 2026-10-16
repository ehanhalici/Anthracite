#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/source/text_source.sats"
staload "data_text/source/text_fields.sats"
extern fun fields_exhausted(): int = "mac#anth_die_int"

fun field {n:nat} .<n>. (n: int(n), source: !Buf, start: int, finish: int): int =
  if n = 0 then start else let
    val separator = text_find_byte(source,start,finish,59)
  in if ige(separator,finish) then finish else field(n-1,source,iadd(separator,1),finish) end

implement text_field(source,start,finish,index) = field(airlock_nat(index),source,start,finish)

fun decimal {n:nat} .<n>. (n: int(n), source: !Buf, p: &int >> _, value: int): int =
  if n = 0 then value else let
    val byte = buf_get(source,p)
  in if ilt(byte,48) orelse igt(byte,57) then value
    else if igt(value,214748364) orelse (ieq(value,214748364) andalso igt(byte,55)) then ~1 else let
      val () = p := iadd(p,1)
    in decimal(n-1,source,p,iadd(imul(value,10),isub(byte,48))) end end

implement text_decimal(source,position,finish) = let
  val start = position
  val value = decimal(airlock_nat(imax(0,isub(finish,position))),source,position,0)
in if ieq(position,start) then ~1 else value end

fun token_end {n:nat} .<n>. (n: int(n), source: !Buf, p: int): int =
  if n = 0 then p else let val byte = buf_get(source,p) in
    if ieq(byte,32) orelse ieq(byte,9) orelse ieq(byte,13) then p else token_end(n-1,source,iadd(p,1)) end

implement text_token_end(source,start,finish) =
  token_end(airlock_nat(imax(0,isub(finish,start))),source,start)
