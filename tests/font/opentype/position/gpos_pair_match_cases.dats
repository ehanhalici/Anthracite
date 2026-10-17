#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
staload "data_font/opentype/position/gpos_values.sats"
staload "data_font/opentype/position/gpos_value_cache_types.sats"
staload "data_font/opentype/position/gpos_value_cache.sats"
staload "data_font/opentype/position/gpos_pair_types.sats"
staload "data_font/opentype/position/gpos_pairs.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/position/gpos_pair_contracts.sats"
fun expected(b: !Buf,t: !GposPairs,first: int,second: int,a: int,c: int,found: bool): int = let
  val r=gpos_pair_query(b,t,first,second)
  val progress=case+ r.progress of | PairContinueSecond() => not(found) | PairContinueFollowing() => found
  val ok=(r.matched=found) andalso ieq(r.first.units.xAdvance,a) andalso ieq(r.second.units.xPlace,c) andalso progress
in if ok then 0 else 1 end
fun checks(b: !Buf,t: !GposPairs,which: PairFixture): int = case+ which of
  | GlyphPairs() => expected(b,t,5,6,~10,2,true)+expected(b,t,5,7,0,0,true)+
    expected(b,t,6,6,0,0,false)+expected(b,t,5,8,0,0,false)
  | ClassPairs() => expected(b,t,5,6,~11,11,true)+expected(b,t,6,9,~12,12,true)+
    expected(b,t,8,4,~1,1,true)+expected(b,t,5,4,~10,10,true)+expected(b,t,4,6,0,0,false)
  | ZeroPairs() => let val r=gpos_pair_query(b,t,5,6) in
    if r.matched andalso ieq(r.first.units.xAdvance,0) andalso
      (case+ r.progress of | PairContinueSecond() => true | PairContinueFollowing() => false) then 0 else 1 end
  | DevicePairs() => let val r=gpos_pair_query(b,t,5,6)
    val a=ot_value_sample(b,r.first,5) and c=ot_value_sample(b,r.second,5)
    in if r.matched andalso ieq(a.xPlace.pixels,~2) andalso ieq(c.yPlace.pixels,7) then 0 else 1 end
  | AbsentSecond() => let val r=gpos_pair_query(b,t,5,6) in
    if r.matched andalso ieq(r.first.units.xAdvance,~10) andalso
      (case+ r.progress of | PairContinueSecond() => true | PairContinueFollowing() => false) then 0 else 1 end
fun check(which: PairFixture): int = let val b=gpos_pair_fixture(which)
  val errors=case+ gpos_pair_parse(b,ot_fixture_span(b),10) of
    | ~PairRejected(e) => 1 | ~PairAccepted(t) => let
      val errors=checks(b,t,which)
      val missing=gpos_pair_query(b,t,5,10) and negative=gpos_pair_query(b,t,5,~1)
      val ()=gpos_pair_dispose(t)
    in iadd(errors,if missing.matched orelse negative.matched then 1 else 0) end
  val ()=buf_free(b)
in errors end
implement gpos_pair_test_matches() = check(GlyphPairs())+check(ClassPairs())+
  check(ZeroPairs())+check(DevicePairs())+check(AbsentSecond())
