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
staload "data_font/opentype/position/gpos_pair_work.sats"
fun fill {n,i:nat | i <= n}{r:nat} .<r>. (remaining: int(r),b: !Buf,set: GposPairSet,
  f: GposPairFormat,cache: OtValueCache(n,i)): GposPairPartial(n) = let
  val filled=ot_value_cache_filled(cache) and capacity=ot_value_cache_count(cache)
  val index=isub(filled,set.start)
  val first=ieq(imod(index,2),0)
  val format=if first then f.first else f.second
  val at=iadd(iadd(4,imul(idiv(index,2),iadd(2,f.stride))),if first then 0 else f.first.size)
in if remaining = 0 then PairValuesPartial(cache)
  else if filled = capacity then let val ()=ot_value_cache_dispose(cache)
    in PairValuesRejected(ot_error(OtReference(),set.span)) end
  else case+ ot_value_parse(b,set.span,at,format,set.floor) of
    | ~ValueRejected(e) => let val ()=ot_value_cache_dispose(cache) in PairValuesRejected(e) end
    | ~ValueAccepted(v) => fill(remaining-1,b,set,f,ot_value_cache_append(cache,v)) end
implement gpos_pair_set_values(b,set,f,cache) = fill(airlock_nat(imul(set.count,2)),b,set,f,cache)
