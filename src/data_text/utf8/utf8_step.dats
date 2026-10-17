#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
#include "data_text/utf8/utf8_encoding.hats"
staload "mem.sats"
staload "data_text/utf8/utf8.sats"
fun byte_at(source: !Buf,limit: int,offset: int,relative: int): int =
  if ilt(relative,isub(limit,offset)) then buf_get(source,iadd(offset,relative)) else 0
implement utf8_step(source,limit,offset) =
  if ilt(offset,0) orelse ige(offset,limit) orelse igt(limit,buf_cap(source))
  then @{kind=Utf8End(),value=0,next=offset} else let
    val window: Utf8Window= @{available=imin(UTF8_MAX_SEQUENCE_BYTES,isub(limit,offset)),first=buf_get(source,offset),
      second=byte_at(source,limit,offset,1),third=byte_at(source,limit,offset,2),fourth=byte_at(source,limit,offset,3)}
  in utf8_window_step(window,offset) end
