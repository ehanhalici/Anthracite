#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi_types.sats"
staload "data_text/unicode_sort.sats"

fun digit(rows: !Buf, i: int, width: int, column: int, divisor: int): int =
  imod(idiv(buf_get32(rows,iadd(imul(i,width),column)),divisor),256)

fun count_keys {n:nat} .<n>. (
  n: int(n), rows: !Buf, counters: !Buf, i: int, width: int, column: int, divisor: int
): void = if n = 0 then () else let
  val key = digit(rows,i,width,column,divisor)
  val () = buf_set32(counters,key,iadd(buf_get32(counters,key),1))
in count_keys(n-1,rows,counters,iadd(i,1),width,column,divisor) end

fun prefixes {n:nat} .<n>. (n: int(n), counters: !Buf, i: int, total: int): void =
  if n = 0 then () else let
    val size = buf_get32(counters,i)
    val () = buf_set32(counters,i,total)
  in prefixes(n-1,counters,iadd(i,1),iadd(total,size)) end

fun copy_row {n:nat} .<n>. (n: int(n), source: !Buf, output: !Buf, from: int, to: int): void =
  if n = 0 then () else let
    val () = buf_set32(output,to,buf_get32(source,from))
  in copy_row(n-1,source,output,iadd(from,1),iadd(to,1)) end

fun scatter {n:nat} .<n>. (
  n: int(n), source: !Buf, output: !Buf, counters: !Buf, i: int, width: int, column: int, divisor: int
): void = if n = 0 then () else let
  val key = digit(source,i,width,column,divisor)
  val target = buf_get32(counters,key)
  val () = copy_row(airlock_nat(width),source,output,imul(i,width),imul(target,width))
  val () = buf_set32(counters,key,iadd(target,1))
in scatter(n-1,source,output,counters,iadd(i,1),width,column,divisor) end

fun radix_round(source: !Buf, output: !Buf, counters: !Buf, count: int, width: int, column: int, divisor: int): void = let
  val () = buf_zero(counters)
  val () = count_keys(airlock_nat(count),source,counters,0,width,column,divisor)
  val () = prefixes(256,counters,0,0)
in scatter(airlock_nat(count),source,output,counters,0,width,column,divisor) end

implement unicode_rows_sort(rows,count,width,column) = let
  val scratch = buf_make(imul(imul(count,width),4))
  val counters = buf_make(1024)
  val () = radix_round(rows,scratch,counters,count,width,column,1)
  val () = radix_round(scratch,rows,counters,count,width,column,256)
  val () = radix_round(rows,scratch,counters,count,width,column,65536)
  val () = copy_row(airlock_nat(imul(count,width)),scratch,rows,0,0)
  val () = buf_free(scratch)
in buf_free(counters) end

implement word_rows_sort(rows,count,width,column) = let
  val scratch=buf_make(imul(imul(count,width),4))
  val counters=buf_make(1024)
  val ()=radix_round(rows,scratch,counters,count,width,column,1)
  val ()=radix_round(scratch,rows,counters,count,width,column,256)
  val ()=radix_round(rows,scratch,counters,count,width,column,65536)
  val ()=radix_round(scratch,rows,counters,count,width,column,16777216)
  val ()=buf_free(scratch)
in buf_free(counters) end
