#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "data_font/opentype/position/gpos_value_types.sats"
staload "data_font/opentype/position/gpos_value_cache_types.sats"
staload "data_font/opentype/position/gpos_value_cache.sats"
extern fun unfinished_value(cache: !OtValueCache(2,1)): OtValueInfo
implement unfinished_value(cache) = ot_value_cache_get(cache,0)
