#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "os/fs.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/gsub_reverse_types.sats"
staload "data_font/gsub_reverse.sats"
staload "data_font/ot_cov_cache_types.sats"
staload "data_font/ot_cov_cache.sats"
staload "opentype_fixture.sats"
staload "font_fixture.sats"
staload "gsub_reverse_contracts.sats"

(* Current {5,6}, backtrack {2} then {1}, lookahead {7}, replacement {8,9}. *)
implement reverse_fixture() = ot_fixture_words("0001 0014 0002 001C 0022 0001 0028 0002 0008 0009 0001 0002 0005 0006 0001 0001 0002 0001 0001 0001 0001 0001 0007")
fun input(): Buf = let
  val b=buf_make(16)
  val ()=buf_set32(b,0,1) and ()=buf_set32(b,1,2)
  val ()=buf_set32(b,2,5) and ()=buf_set32(b,3,7)
in b end
fun expect(b: !Buf,t: !GsubReverse,v: !Buf,count: int,start: int,output: int): int = let
  val r=gsub_reverse_match(b,t,v,count,start)
in if r.matched andalso ieq(r.glyph,output) then 0 else 1 end
fun miss(b: !Buf,t: !GsubReverse,v: !Buf,count: int,start: int): int = let
  val r=gsub_reverse_match(b,t,v,count,start)
in if not(r.matched) then 0 else 1 end
fun queries(b: !Buf,t: !GsubReverse): int = let
  val v=input()
  val good=expect(b,t,v,4,2,8)+miss(b,t,v,3,2)+miss(b,t,v,4,1)+
    miss(b,t,v,5,2)+miss(b,t,v,4,~1)+miss(b,t,v,4,4)
  val ()=buf_set32(v,2,6)
  val second=expect(b,t,v,4,2,9)
  val ()=buf_set32(v,1,1) and ()=buf_set32(v,0,2)
  val reversed=miss(b,t,v,4,2)
  val ()=buf_free(v)
in good+second+reversed end
fun parsed(b: !Buf): int = case+ gsub_reverse_parse(b,ot_fixture_span(b),10) of
  | ~ReverseRejected(e) => 1 | ~ReverseAccepted(t) => let
    val errors=queries(b,t) val ()=gsub_reverse_dispose(t)
  in errors end
fun no_context(): int = let
  val b=ot_fixture_words("0001 000C 0000 0000 0001 0001 0001 0001 0000")
  val errors: int=case+ gsub_reverse_parse(b,ot_fixture_span(b),2) of
    | ~ReverseRejected(e) => 1 | ~ReverseAccepted(t) => let
      val v=buf_make(4)
      val errors=expect(b,t,v,1,0,1)
      val ()=buf_free(v) and ()=gsub_reverse_dispose(t)
    in errors end
  val ()=buf_free(b)
in errors end
implement reverse_test_context() = let
  val b=reverse_fixture()
  val errors=parsed(b)+no_context()
  val ()=buf_free(b)
in errors end
