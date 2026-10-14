#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8.sats"

fun continuation(b: int): bool = ige(b,128) andalso ile(b,191)
fun sequence_length(b: int): int =
  if ige(b,194) andalso ile(b,223) then 2
  else if ige(b,224) andalso ile(b,239) then 3
  else if ige(b,240) andalso ile(b,244) then 4 else 0
fun second_valid(lead: int,b: int): bool =
  if ieq(lead,224) then ige(b,160) andalso ile(b,191)
  else if ieq(lead,237) then ige(b,128) andalso ile(b,159)
  else if ieq(lead,240) then ige(b,144) andalso ile(b,191)
  else if ieq(lead,244) then ige(b,128) andalso ile(b,143)
  else continuation(b)
fun initial_value(lead: int,count: int): int =
  if ieq(count,2) then isub(lead,192)
  else if ieq(count,3) then isub(lead,224) else isub(lead,240)
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
    else decode_tail(left-1,w,iadd(index,1),iadd(offset,1),iadd(imul(value,64),isub(byte,128))) end
fun decode_multibyte(w: Utf8Window,offset: int,lead: int): Utf8Step = let
  val count=sequence_length(lead)
  val next=iadd(offset,1)
in if ieq(count,0) orelse ile(w.available,1) then malformed(next)
  else if not(second_valid(lead,w.second)) then malformed(next)
  else decode_tail(airlock_nat(isub(count,1)),w,1,next,initial_value(lead,count)) end
implement utf8_window_step(w,offset) =
  if ilt(offset,0) orelse ile(w.available,0) orelse igt(w.available,4) orelse igt(offset,isub(2147483647,w.available))
  then @{kind=Utf8End(),value=0,next=offset}
  else let val lead=w.first in
    if ige(lead,0) andalso ilt(lead,128) then scalar(lead,iadd(offset,1))
    else decode_multibyte(w,offset,lead) end
