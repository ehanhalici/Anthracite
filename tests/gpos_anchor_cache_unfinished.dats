#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/gpos_anchor_cache.sats"
extern fun unfinished_anchor(cache: !OtAnchorCache(2,1)): OtAnchorSlot
implement unfinished_anchor(cache) = ot_anchor_cache_get(cache,0)
