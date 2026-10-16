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
implement gpos_pair_sets_make(count) = let
  val zero: GposPairSet= @{span= @{offset=0,length=0},count=0,start=0,floor=0}
  val rows=arrayptr_make_elt<GposPairSet>(g1int2uint_int_size(count),zero)
in GposPairSets(rows,count,0) end
implement gpos_pair_sets_count(sets) = let val+ GposPairSets(rows,count,filled)=sets in count end
implement gpos_pair_sets_filled(sets) = let val+ GposPairSets(rows,count,filled)=sets in filled end
implement gpos_pair_sets_append(sets,v) = let val+ ~GposPairSets(rows,count,filled)=sets
  val ()=arrayptr_set_at<GposPairSet>(rows,g1int2uint_int_size(filled),v)
in GposPairSets(rows,count,filled+1) end
implement gpos_pair_sets_get(sets,index) = let val+ GposPairSets(rows,count,filled)=sets in
  arrayptr_get_at<GposPairSet>(rows,g1int2uint_int_size(airlock_below(index,count))) end
implement gpos_pair_sets_dispose(sets) = let val+ ~GposPairSets(rows,count,filled)=sets in arrayptr_free(rows) end
