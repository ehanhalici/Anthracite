#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/resources/font.sats"
staload "data_font/resources/private/font_storage.sats"
staload "data_font/atlas/private/font_cache_types.sats"
staload "data_font/atlas/private/font_cache.sats"
staload "data_font/atlas/private/font_cache_work.sats"
staload "data_font/raster/private/font_math.sats"
implement font_cache_kind_code(kind) = case+ kind of
  | CacheCodepoint() => 0 | CachePrimaryGlyph() => 1 | CacheFallbackGlyph() => 2
implement font_cache_hash(key) = font_mod(iadd(imul(key.value,17),3),1024)
implement font_cache_matches(f,slot,key) = ieq(cache_i(f,slot,0),1)
  andalso ieq(cache_i(f,slot,1),key.value)
  andalso ieq(cache_i(f,slot,9),font_cache_kind_code(key.kind)) andalso ieq(cache_i(f,slot,10),key.ppem)
