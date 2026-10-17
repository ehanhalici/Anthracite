#include "share/atspre_staload.hats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/coverage/ot_cov_cache_types.sats"
staload "data_font/opentype/coverage/ot_cov_cache.sats"
fun unfinished(cache: !OtCoverageCache(2,1)): OtCoverageInfo = ot_cov_cache_get(cache,0)
