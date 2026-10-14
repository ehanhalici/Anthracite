#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8.sats"
staload "os/fs.sats"
staload "utf8_contracts.sats"

fun sample(): Buf = let
  val b=buf_make(15)
  val ()=buf_set(b,0,196) and ()=buf_set(b,1,176)
  val ()=buf_set(b,2,204) and ()=buf_set(b,3,135)
  val ()=buf_set(b,4,216) and ()=buf_set(b,5,168)
  val ()=buf_set(b,6,217) and ()=buf_set(b,7,142)
  val ()=buf_set(b,8,240) and ()=buf_set(b,9,159)
  val ()=buf_set(b,10,152) and ()=buf_set(b,11,128)
  val ()=buf_set(b,13,226) and ()=buf_set(b,14,130)
in b end
fun values(t: !ScalarText): bool =
  ieq(scalar_count(t),7) andalso ieq(scalar_errors(t),1) andalso
  ieq(scalar_value(t,0),304) andalso ieq(scalar_value(t,1),775) andalso
  ieq(scalar_value(t,2),1576) andalso ieq(scalar_value(t,3),1614) andalso
  ieq(scalar_value(t,4),128512) andalso ieq(scalar_value(t,5),0) andalso
  ieq(scalar_value(t,6),65533)
fun spans(t: !ScalarText): bool =
  ieq(scalar_start(t,0),0) andalso ieq(scalar_end(t,0),2) andalso
  ieq(scalar_start(t,3),6) andalso ieq(scalar_end(t,3),8) andalso
  ieq(scalar_start(t,4),8) andalso ieq(scalar_end(t,4),12) andalso
  ieq(scalar_start(t,5),12) andalso ieq(scalar_end(t,5),13) andalso
  ieq(scalar_start(t,6),13) andalso ieq(scalar_end(t,6),15)
fun exact(b: !Buf): int = let val baseline=mem_live() in case+ text_decode(b,15) of
  | ~InvalidTextSpan() => 1 | ~DecodedText(t) => let
    val ok=values(t) andalso spans(t) andalso ieq(isub(mem_live(),baseline),84)
    val ()=scalar_dispose(t)
  in if ok andalso ieq(mem_live(),baseline) then 0 else 1 end end
fun invalid(b: !Buf,length: int): int = case+ text_decode(b,length) of
  | ~InvalidTextSpan() => 0 | ~DecodedText(t) => let val ()=scalar_dispose(t) in 1 end
fun ended(b: !Buf,limit: int,offset: int): int = let val step=utf8_step(b,limit,offset) in
  case+ step.kind of
  | Utf8End() => 0 | Utf8Scalar() => 1 | Utf8Malformed() => 1 end
fun empty(b: !Buf): int = case+ text_decode(b,0) of
  | ~InvalidTextSpan() => 1 | ~DecodedText(t) => let
    val ok=ieq(scalar_count(t),0) andalso ieq(scalar_errors(t),0)
    val ()=scalar_dispose(t)
  in if ok then 0 else 1 end
implement utf8_test_storage() = let
  val b=sample()
  val errors=exact(b)+empty(b)+invalid(b,~1)+invalid(b,16)+invalid(b,268435457)+
    ended(b,15,~1)+ended(b,15,15)+ended(b,16,0)+ended(b,~1,0)
  val ()=buf_free(b)
in errors end
