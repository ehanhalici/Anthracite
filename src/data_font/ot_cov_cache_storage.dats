#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_cov_cache_types.sats"
staload "data_font/ot_cov_cache.sats"
fun empty(): OtCoverageInfo = @{span= @{offset=0,length=0},encoding=OtList(),count=0,total=0}
implement ot_cov_cache_make(count) = let
  val rows=arrayptr_make_elt<OtCoverageInfo>(g1int2uint_int_size(count),empty())
in OtCoverageCache(rows,count,0) end
implement ot_cov_cache_append(cache,info) = let
  val+ ~OtCoverageCache(rows,count,filled)=cache
  val ()=arrayptr_set_at<OtCoverageInfo>(rows,g1int2uint_int_size(filled),info)
in OtCoverageCache(rows,count,filled+1) end
implement ot_cov_cache_count(cache) = let val+ OtCoverageCache(rows,count,filled)=cache in count end
implement ot_cov_cache_filled(cache) = let val+ OtCoverageCache(rows,count,filled)=cache in filled end
implement ot_cov_cache_get(cache,index) = let val+ OtCoverageCache(rows,count,filled)=cache in
  arrayptr_get_at<OtCoverageInfo>(rows,g1int2uint_int_size(airlock_below(index,count))) end
implement ot_cov_cache_dispose(cache) = let val+ ~OtCoverageCache(rows,count,filled)=cache in arrayptr_free(rows) end
