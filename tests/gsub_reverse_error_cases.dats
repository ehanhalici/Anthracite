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

fun reject(b: !Buf,s: OtSpan,glyphs: int): int = case+ gsub_reverse_parse(b,s,glyphs) of
  | ~ReverseRejected(e) => 0 | ~ReverseAccepted(t) => let val ()=gsub_reverse_dispose(t) in 1 end
fun cuts {n:nat} .<n>. (n: int(n),b: !Buf,length: int): int =
  if n = 0 then 0 else reject(b,@{offset=8,length=length},10)+cuts(n-1,b,iadd(length,1))
fun changed(at: int,value: int): int = let
  val b=reverse_fixture()
  val ()=ot_fixture_put16(b,at,value)
  val errors=reject(b,ot_fixture_span(b),10)
  val ()=buf_free(b)
in errors end
implement reverse_test_errors() = let
  val b=reverse_fixture()
  val errors=cuts(airlock_nat(isub(buf_len(b),8)),b,0)+reject(b,ot_fixture_span(b),0)+
    reject(b,ot_fixture_span(b),65536)+reject(b,@{offset= ~1,length=48},10)+
    reject(b,@{offset=8,length=2147483647},10)
  val ()=buf_free(b)
in errors+changed(0,2)+changed(2,0)+changed(2,19)+changed(4,65535)+changed(6,0)+
  changed(10,65535)+changed(12,65535)+changed(14,1)+changed(16,10)+changed(22,3)+changed(26,5) end
