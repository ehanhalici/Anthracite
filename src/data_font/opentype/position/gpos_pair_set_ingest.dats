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
staload "data_font/opentype/position/gpos_pair_sets.sats"
staload "data_font/opentype/position/gpos_pair_work.sats"
fun complete {n,m,j:nat | j <= m}(info: GposPairInfo,sets: GposPairSets(n,n),
  cache: OtValueCache(m,j)): GposPairRead =
  if ot_value_cache_filled(cache) = ot_value_cache_count(cache) then PairAccepted(PairGlyphs(info,sets,cache))
  else let val ()=gpos_pair_sets_dispose(sets) and ()=ot_value_cache_dispose(cache)
    in PairRejected(ot_error(OtReference(),info.span)) end
fun fill {n,i:nat | i <= n}{m,j:nat | j <= m} .<n-i>. (index: int(i),b: !Buf,info: GposPairInfo,
  sets: GposPairSets(n,n),cache: OtValueCache(m,j)): GposPairRead =
  if index = gpos_pair_sets_count(sets) then complete(info,sets,cache) else let
    val set=gpos_pair_sets_get(sets,index)
  in case+ gpos_pair_set_values(b,set,info.formats,cache) of
    | ~PairValuesRejected(e) => let val ()=gpos_pair_sets_dispose(sets) in PairRejected(e) end
    | ~PairValuesPartial(next) => fill(index+1,b,info,sets,next) end
implement gpos_pair_set_ingest(b,info,sets,count) = fill(0,b,info,sets,ot_value_cache_make(count))
