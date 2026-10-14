#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/font.sats"
staload "data_font/private/font_storage.sats"
staload "data_font/private/font_cache_types.sats"
staload "data_font/private/font_cache.sats"
staload "data_font/private/font_cache_work.sats"
implement cache_get(f,cp,g) = cache_get_key(f,@{kind=CacheCodepoint(),value=cp,ppem=f_get_px(f)},g)
implement cache_put(f,cp,g) = cache_put_key(f,@{kind=CacheCodepoint(),value=cp,ppem=f_get_px(f)},g)
implement cache_put_key(f,key,g) = font_cache_write(f,font_cache_find(f,key),key,g)
fun clear{n:nat} .<n>. (left: int(n),f: !Font,i: int): void = if left = 0 then () else let
  val ()=cache_s(f,i,0,0)
in clear(left-1,f,i+1) end
implement clear_cache(f,i) = let val start=airlock_below(i,1025) in
  clear(airlock_nat(1024-start),f,start) end
