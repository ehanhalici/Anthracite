#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
#include "data_text/utf8/utf8_encoding.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8/utf8.sats"

fun continuation(b: int): bool = ige(b,UTF8_CONTINUATION_BASE) andalso ile(b,UTF8_CONTINUATION_LIMIT)
fun sequence_length(b: int): int =
  if ige(b,UTF8_TWO_BYTE_MIN_LEAD) andalso ile(b,UTF8_TWO_BYTE_MAX_LEAD) then 2
  else if ige(b,UTF8_THREE_BYTE_BASE) andalso ile(b,UTF8_THREE_BYTE_MAX_LEAD) then 3
  else if ige(b,UTF8_FOUR_BYTE_BASE) andalso ile(b,UTF8_FOUR_BYTE_MAX_LEAD) then UTF8_MAX_SEQUENCE_BYTES else 0
fun second_valid(lead: int,b: int): bool =
  if ieq(lead,UTF8_THREE_BYTE_BASE) then ige(b,UTF8_THREE_BYTE_MIN_SECOND) andalso ile(b,UTF8_CONTINUATION_LIMIT)
  else if ieq(lead,UTF8_SURROGATE_LEAD) then ige(b,UTF8_CONTINUATION_BASE) andalso ile(b,UTF8_SURROGATE_MAX_SECOND)
  else if ieq(lead,UTF8_FOUR_BYTE_BASE) then ige(b,UTF8_FOUR_BYTE_MIN_SECOND) andalso ile(b,UTF8_CONTINUATION_LIMIT)
  else if ieq(lead,UTF8_FOUR_BYTE_MAX_LEAD) then ige(b,UTF8_CONTINUATION_BASE) andalso ile(b,UTF8_FOUR_BYTE_MAX_SECOND)
  else continuation(b)
fun initial_value(lead: int,count: int): int =
  if ieq(count,2) then isub(lead,UTF8_TWO_BYTE_BASE)
  else if ieq(count,3) then isub(lead,UTF8_THREE_BYTE_BASE) else isub(lead,UTF8_FOUR_BYTE_BASE)
fun malformed(offset: int): Utf8Step = @{kind=Utf8Malformed(),value=0,next=offset}
fun scalar(value: int,offset: int): Utf8Step = @{kind=Utf8Scalar(),value=value,next=offset}
fun byte_at(w: Utf8Window,index: int): int =
  if ieq(index,0) then w.first else if ieq(index,1) then w.second else if ieq(index,2) then w.third else w.fourth
fun decode_tail {left:nat} .<left>. (
  left: int(left),w: Utf8Window,index: int,offset: int,value: int
): Utf8Step =
  if left = 0 then scalar(value,offset)
  else if ige(index,w.available) then malformed(offset)
  else let val byte=byte_at(w,index) in
    if not(continuation(byte)) then malformed(offset)
    else decode_tail(left-1,w,iadd(index,1),iadd(offset,1),
      iadd(imul(value,UTF8_CONTINUATION_RADIX),isub(byte,UTF8_CONTINUATION_BASE))) end
fun decode_multibyte(w: Utf8Window,offset: int,lead: int): Utf8Step = let
  val count=sequence_length(lead)
  val next=iadd(offset,1)
in if ieq(count,0) orelse ile(w.available,1) then malformed(next)
  else if not(second_valid(lead,w.second)) then malformed(next)
  else decode_tail(airlock_nat(isub(count,1)),w,1,next,initial_value(lead,count)) end
implement utf8_window_step(w,offset) =
  if ilt(offset,0) orelse ile(w.available,0) orelse igt(w.available,UTF8_MAX_SEQUENCE_BYTES)
    orelse igt(offset,isub(SIGNED_INT_MAX_VALUE,w.available))
  then @{kind=Utf8End(),value=0,next=offset}
  else let val lead=w.first in
    if ige(lead,0) andalso ilt(lead,ASCII_LIMIT) then scalar(lead,iadd(offset,1))
    else decode_multibyte(w,offset,lead) end
