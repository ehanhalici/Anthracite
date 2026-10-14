#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_values.sats"
staload "data_font/gpos_value_cache_types.sats"
staload "data_font/gpos_value_cache.sats"
staload "data_font/gpos_pair_types.sats"
staload "data_font/gpos_pairs.sats"
staload "opentype_fixture.sats"
staload "gpos_pair_contracts.sats"
fun rows {n:nat} .<n>. (n: int(n),b: !Buf,i: int): void =
  if n = 0 then () else let val ()=ot_fixture_put16(b,iadd(20,imul(i,2)),i)
  in rows(n-1,b,iadd(i,1)) end
fun fixture(): Buf = let
  var b=ot_fixture_words("0001 000C 0000 0000 0001 0012 0001 0001 0000 FFFF")
  val ()=buf_resize(b,131098) and ()=buf_set_len(b,131098)
  val ()=rows(65535,b,0)
in b end
fun queries {n:nat} .<n>. (n: int(n),b: !Buf,t: !GposPairs,i: int): int =
  if n = 0 then 0 else let val r=gpos_pair_query(b,t,0,i)
    val ok=r.matched andalso ieq(r.first.units.xAdvance,0) andalso ieq(r.second.units.xAdvance,0)
  in iadd(if ok then 0 else 1,queries(n-1,b,t,iadd(i,1))) end
implement gpos_pair_test_stress() = let val b=fixture()
  val errors=case+ gpos_pair_parse(b,ot_fixture_span(b),65535) of
    | ~PairRejected(e) => 1 | ~PairAccepted(t) => let
      val errors=queries(65535,b,t,0) val ()=gpos_pair_dispose(t) in errors end
  val ()=buf_free(b)
in errors end
