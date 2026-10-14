#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8.sats"
staload "os/fs.sats"
staload "utf8_contracts.sats"

fun one(b: !Buf,cp: int): int = let val ()=buf_set(b,0,cp) in 1 end
fun two(b: !Buf,cp: int): int = let
  val ()=buf_set(b,0,iadd(192,idiv(cp,64)))
  val ()=buf_set(b,1,iadd(128,imod(cp,64)))
in 2 end
fun three(b: !Buf,cp: int): int = let
  val ()=buf_set(b,0,iadd(224,idiv(cp,4096)))
  val ()=buf_set(b,1,iadd(128,imod(idiv(cp,64),64)))
  val ()=buf_set(b,2,iadd(128,imod(cp,64)))
in 3 end
fun four(b: !Buf,cp: int): int = let
  val ()=buf_set(b,0,iadd(240,idiv(cp,262144)))
  val ()=buf_set(b,1,iadd(128,imod(idiv(cp,4096),64)))
  val ()=buf_set(b,2,iadd(128,imod(idiv(cp,64),64)))
  val ()=buf_set(b,3,iadd(128,imod(cp,64)))
in 4 end
implement utf8_test_write(b,cp) =
  if ilt(cp,128) then one(b,cp) else if ilt(cp,2048) then two(b,cp)
  else if ilt(cp,65536) then three(b,cp) else four(b,cp)
