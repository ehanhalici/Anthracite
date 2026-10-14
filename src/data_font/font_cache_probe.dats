#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/font.sats"
staload "data_font/private/font_storage.sats"
staload "data_font/private/font_cache_types.sats"
staload "data_font/private/font_cache.sats"
staload "data_font/private/font_cache_work.sats"
staload "data_font/private/font_math.sats"
fun query{n:nat} .<n>. (left: int(n),f: !Font,key: FontCacheKey,g: &gmet >> _,slot: int): int =
  if left = 0 then let val ()=fill_g(g,0,0,0,0,0,0,0) in 0 end
  else if font_cache_matches(f,slot,key) then let val ()=font_cache_read(f,slot,g) in 1 end
  else query(left-1,f,key,g,font_mod(slot+1,1024))
fun find{n:nat} .<n>. (left: int(n),f: !Font,key: FontCacheKey,slot: int,home: int): int =
  if left = 0 then home else if cache_i(f,slot,0) = 0 orelse font_cache_matches(f,slot,key) then slot
  else find(left-1,f,key,font_mod(slot+1,1024),home)
implement cache_get_key(f,key,g) = query(24,f,key,g,font_cache_hash(key))
implement font_cache_find(f,key) = let val home=font_cache_hash(key) in find(24,f,key,home,home) end
