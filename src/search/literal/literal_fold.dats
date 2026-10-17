#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
#include "data_text/utf8/utf8_encoding.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/utf8/utf8_work.sats"
staload "search/literal/literal_search.sats"
staload "search/literal/literal_work.sats"
macdef UTF8_TWO_BYTE_SCALAR_LIMIT = 2048
macdef UTF8_THREE_BYTE_SCALAR_LIMIT = WORD16_MODULUS
macdef UTF8_TWO_CONTINUATION_DIVISOR = UTF8_CONTINUATION_RADIX * UTF8_CONTINUATION_RADIX
macdef UTF8_THREE_CONTINUATION_DIVISOR = UTF8_TWO_CONTINUATION_DIVISOR * UTF8_CONTINUATION_RADIX
fun append_word(b: &Buf >> _,value: int): void = let val bytes=buf_len(b)
  val ()=buf_ensure(b,iadd(bytes,WORD32_BYTES)) val ()=buf_set32(b,idiv(bytes,WORD32_BYTES),value)
in buf_set_len(b,iadd(bytes,WORD32_BYTES)) end
fun append_byte(text: &Buf >> _,starts: &Buf >> _,ends: &Buf >> _,byte: int,start: int,finish: int): void = let
  val ()=buf_push(text,byte) val ()=append_word(starts,start)
in append_word(ends,finish) end
fun encoded_size(cp: int): int = if ilt(cp,ASCII_LIMIT) then 1 else if ilt(cp,UTF8_TWO_BYTE_SCALAR_LIMIT) then 2
  else if ilt(cp,UTF8_THREE_BYTE_SCALAR_LIMIT) then 3 else UTF8_MAX_SEQUENCE_BYTES
fun continuation{n:nat} .<n>. (left: int(n),text: &Buf >> _,starts: &Buf >> _,ends: &Buf >> _,cp: int,
  divisor: int,start: int,finish: int): void =
  if left = 0 then () else let
    val byte=iadd(UTF8_CONTINUATION_BASE,imod(idiv(cp,divisor),UTF8_CONTINUATION_RADIX))
    val ()=append_byte(text,starts,ends,byte,start,finish)
  in continuation(left-1,text,starts,ends,cp,idiv(divisor,UTF8_CONTINUATION_RADIX),start,finish) end
fun append_scalar(text: &Buf >> _,starts: &Buf >> _,ends: &Buf >> _,cp: int,start: int,finish: int): void = let
  val size=encoded_size(cp)
  val divisor=if ieq(size,1) then 1 else if ieq(size,2) then UTF8_CONTINUATION_RADIX
    else if ieq(size,3) then UTF8_TWO_CONTINUATION_DIVISOR else UTF8_THREE_CONTINUATION_DIVISOR
  val base=if ieq(size,1) then 0 else if ieq(size,2) then UTF8_TWO_BYTE_BASE
    else if ieq(size,3) then UTF8_THREE_BYTE_BASE else UTF8_FOUR_BYTE_BASE
  val ()=append_byte(text,starts,ends,iadd(base,idiv(cp,divisor)),start,finish)
in continuation(airlock_nat(isub(size,1)),text,starts,ends,cp,idiv(divisor,UTF8_CONTINUATION_RADIX),start,finish) end
fun fold{n:nat} .<n>. (left: int(n),table: !Buf,source: !Buf,p: int,length: int,
  text: &Buf >> _,starts: &Buf >> _,ends: &Buf >> _): void =
  if ige(p,length) then () else if not(recursion_fuel_available(left)) then () else let
    val unit=utf8_unit(utf8_step(source,length,p),p)
    val ()=append_scalar(text,starts,ends,literal_case_lookup(table,unit.cp),p,unit.next)
  in fold(left-1,table,source,unit.next,length,text,starts,ends) end
implement literal_fold(table,source,text,starts,ends) =
  fold(airlock_nat(iadd(buf_len(source),1)),table,source,0,buf_len(source),text,starts,ends)
