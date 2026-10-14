#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/ot_single_lookup_types.sats"
staload "data_font/ot_single_lookup.sats"
staload "opentype_fixture.sats"
staload "glyph_pass_contracts.sats"
fun offsets{n:nat} .<n>. (n: int(n),b: !Buf,i: int): void =
  if n = 0 then () else let val ()=ot_fixture_put16(b,iadd(6,imul(i,2)),65534)
  in offsets(n-1,b,iadd(i,1)) end
implement pass_test_large_lookup() = let
  var b=ot_fixture_words("0001 0000 7FFC")
  val ()=buf_resize(b,65554)
  val ()=offsets(32764,b,0)
  val ()=ot_fixture_put16(b,65534,1) and ()=ot_fixture_put16(b,65536,6)
  val ()=ot_fixture_put16(b,65538,1) and ()=ot_fixture_put16(b,65540,1)
  val ()=ot_fixture_put16(b,65542,1) and ()=ot_fixture_put16(b,65544,10)
  val ()=buf_set_len(b,65554)
in b end
implement pass_test_cache_stress() = let
  val b=pass_test_large_lookup()
  val errors: int=case+ ot_single_lookup_parse(b,ot_fixture_span(b),128) of
    | ~SingleLookupRejected(e) => 1 | ~SingleLookupAccepted(t) => let
      val a=ot_single_lookup_query(b,t,10) and m=ot_single_lookup_query(b,t,11)
      val h=ot_single_lookup_header(t)
      val ok=a.matched andalso ieq(a.glyph,11) andalso not(m.matched) andalso ieq(h.count,32764)
      val ()=ot_single_lookup_dispose(t)
    in if ok then 0 else 1 end
  val ()=buf_free(b)
in errors end
