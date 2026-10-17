#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "os/fs.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/opentype/substitution/gsub_reverse_types.sats"
staload "data_font/opentype/substitution/gsub_reverse.sats"
staload "data_font/opentype/coverage/ot_cov_cache_types.sats"
staload "data_font/opentype/coverage/ot_cov_cache.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/resources/font_fixture.sats"
staload "font/opentype/substitution/gsub_reverse_contracts.sats"

fun offsets {n:nat} .<n>. (n: int(n),b: !Buf,at: int): void =
  if n = 0 then () else let val ()=fixture_put16(b,at,65534) in
    offsets(n-1,b,iadd(at,2)) end
fun fixture(): Buf = let
  val b=buf_make(65548)
  val ()=fixture_put16(b,8,1) and ()=fixture_put16(b,10,65534)
  val ()=fixture_put16(b,12,32761)
  val ()=offsets(32761,b,14)
  val ()=fixture_put16(b,WORD16_MODULUS,0) and ()=fixture_put16(b,65538,1)
  val ()=fixture_put16(b,65540,1)
  val ()=fixture_put16(b,65542,1) and ()=fixture_put16(b,65544,1)
  val ()=fixture_put16(b,65546,0)
  val ()=buf_set_len(b,65548)
in b end
fun parsed(b: !Buf): int = case+ gsub_reverse_parse(b,ot_fixture_span(b),2) of
  | ~ReverseRejected(e) => 1 | ~ReverseAccepted(t) => let
    val input=buf_make(131048)
    val r=gsub_reverse_match(b,t,input,32762,32761)
    val ()=buf_set32(input,0,1)
    val bad=gsub_reverse_match(b,t,input,32762,32761)
    val ok=r.matched andalso ieq(r.glyph,1) andalso not(bad.matched)
    val ()=buf_free(input) and ()=gsub_reverse_dispose(t)
  in if ok then 0 else 1 end
implement reverse_test_stress() = let
  val b=fixture()
  val errors=parsed(b)
  val ()=buf_free(b)
in errors end
