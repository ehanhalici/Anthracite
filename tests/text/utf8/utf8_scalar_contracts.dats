#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8/utf8.sats"
staload "os/fs.sats"
staload "text/utf8/utf8_contracts.sats"

fun scalar(b: !Buf,cp: int): int = let
  val count=utf8_test_write(b,cp)
  val step=utf8_step(b,count,0)
in case+ step.kind of
  | Utf8End() => 1 | Utf8Malformed() => 1
  | Utf8Scalar() => if ieq(step.value,cp) andalso ieq(step.next,count) then 0 else 1 end
fun scalars {n:nat} .<n>. (n: int(n),b: !Buf,cp: int,total: int): int =
  if n = 0 then total else let
    val error: int=if ige(cp,UNICODE_SURROGATE_START) andalso ile(cp,57343) then 0 else scalar(b,cp)
  in scalars(n-1,b,iadd(cp,1),iadd(total,error)) end
fun first_bytes {n:nat} .<n>. (n: int(n),b: !Buf,byte: int,total: int): int =
  if n = 0 then total else let
    val ()=buf_set(b,0,byte)
    val step=utf8_step(b,1,0)
    val error: int=case+ step.kind of
      | Utf8End() => 1
      | Utf8Scalar() => if ilt(byte,128) andalso ieq(step.value,byte) andalso ieq(step.next,1) then 0 else 1
      | Utf8Malformed() => if ige(byte,128) andalso ieq(step.next,1) then 0 else 1
  in first_bytes(n-1,b,iadd(byte,1),iadd(total,error)) end
implement utf8_test_scalars() = let
  val b=buf_make(4)
  val errors=scalars(1114112,b,0,0)+first_bytes(256,b,0,0)
  val ()=buf_free(b)
in errors end
