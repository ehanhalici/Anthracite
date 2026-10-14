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
fun reject(b: !Buf,s: OtSpan,glyphs: int): int = case+ gpos_pair_parse(b,s,glyphs) of
  | ~PairRejected(e) => 0 | ~PairAccepted(t) => let val ()=gpos_pair_dispose(t) in 1 end
fun cuts {n:nat} .<n>. (n: int(n),b: !Buf,len: int): int =
  if n = 0 then 0 else iadd(reject(b,@{offset=8,length=len},10),cuts(n-1,b,iadd(len,1)))
fun truncated(which: PairFixture): int = let val b=gpos_pair_fixture(which)
  val errors=cuts(airlock_nat(isub(buf_len(b),8)),b,0) val ()=buf_free(b) in errors end
fun change(which: PairFixture,at: int,value: int): int = let val b=gpos_pair_fixture(which)
  val ()=ot_fixture_put16(b,at,value)
  val errors=reject(b,ot_fixture_span(b),10) val ()=buf_free(b) in errors end
fun domains(): int = let val b=gpos_pair_fixture(GlyphPairs())
  val errors=reject(b,ot_fixture_span(b),0)+reject(b,ot_fixture_span(b),65536)+
    reject(b,@{offset= ~1,length=20},10)+reject(b,@{offset=8,length=2147483647},10)
  val ()=buf_free(b)
in errors end
implement gpos_pair_test_errors() = domains()+truncated(GlyphPairs())+truncated(ClassPairs())+
  truncated(ZeroPairs())+truncated(DevicePairs())+truncated(AbsentSecond())+
  change(GlyphPairs(),0,3)+change(GlyphPairs(),2,0)+change(GlyphPairs(),4,256)+
  change(GlyphPairs(),6,256)+change(GlyphPairs(),8,1)+change(GlyphPairs(),10,0)+
  change(GlyphPairs(),24,10)+change(GlyphPairs(),30,6)+change(DevicePairs(),24,6)+
  change(ClassPairs(),8,0)+change(ClassPairs(),10,0)+change(ClassPairs(),12,0)+
  change(ClassPairs(),14,0)+change(ClassPairs(),58,2)+change(ClassPairs(),14,65535)
