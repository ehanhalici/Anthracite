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
staload "data_font/opentype/position/gpos_pair_sets.sats"
staload "data_font/opentype/position/gpos_pair_work.sats"
implement gpos_pair_missing() = @{matched=false,first=ot_value_zero(),second=ot_value_zero(),progress=PairContinueSecond()}
implement gpos_pair_view(cache,index,progress) = @{matched=true,first=ot_value_cache_get(cache,index),
  second=ot_value_cache_get(cache,iadd(index,1)),progress=progress}
implement gpos_pair_dispose(table) = case+ table of
  | ~PairNoOpClasses(info) => ()
  | ~PairClasses(info,cache) => ot_value_cache_dispose(cache)
  | ~PairGlyphs(info,sets,cache) => let val ()=gpos_pair_sets_dispose(sets) in ot_value_cache_dispose(cache) end
