#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_text/unicode_property.sats"
staload "data_text/property_writer.sats"

fun emit(output: &Buf >> _, first: int, last: int, value: int, count: int): void = let
  val at = iadd(4,imul(count,3))
  val () = buf_ensure(output,imul(iadd(at,3),4))
  val () = buf_set32(output,at,first)
  val () = buf_set32(output,iadd(at,1),last)
in buf_set32(output,iadd(at,2),value) end

fun compress {n:nat} .<n>. (
  n: int(n), dense: !Buf, cp: int, start: int, previous: int, output: &Buf >> _, count: int
): int =
  if n = 0 then let val () = emit(output,start,isub(cp,1),previous,count) in iadd(count,1) end
  else let val value = buf_get32(dense,cp) in
    if ieq(value,previous) then compress(n-1,dense,iadd(cp,1),start,previous,output,count)
    else let val () = emit(output,start,isub(cp,1),previous,count) in
      compress(n-1,dense,iadd(cp,1),cp,value,output,iadd(count,1)) end end

fun header{kind:int}(output: !Buf, domain: PropertyDomain(kind), count: int): void = let
  val () = buf_set32(output,0,PROPERTY_MAGIC)
  val () = buf_set32(output,1,PROPERTY_VERSION)
  val () = buf_set32(output,2,property_domain_code(domain))
in buf_set32(output,3,count) end

implement property_write(domain,dense,path) = let
  var output = buf_make(65536)
  val count = compress(1114111,dense,1,0,buf_get32(dense,0),output,0)
  val () = header(output,domain,count)
  val size = iadd(16,imul(count,12))
  val () = buf_set_len(output,size)
  val written = fs_write_buf(path,output,size)
  val () = buf_free(output)
in ieq(written,1) end
