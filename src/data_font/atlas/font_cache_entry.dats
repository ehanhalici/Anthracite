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
implement font_cache_read(f,slot,g) = fill_g(g,cache_i(f,slot,2),cache_i(f,slot,3),
  cache_i(f,slot,4),cache_i(f,slot,5),cache_i(f,slot,6),cache_i(f,slot,7),cache_i(f,slot,8))
implement font_cache_write(f,slot,key,g) = let
  val ()=cache_s(f,slot,0,1) and ()=cache_s(f,slot,1,key.value)
  val ()=cache_s(f,slot,2,g.ax) and ()=cache_s(f,slot,3,g.bx) and ()=cache_s(f,slot,4,g.top)
  val ()=cache_s(f,slot,5,g.bw) and ()=cache_s(f,slot,6,g.bh)
  val ()=cache_s(f,slot,7,g.x0) and ()=cache_s(f,slot,8,g.y0)
  val ()=cache_s(f,slot,9,font_cache_kind_code(key.kind)) and ()=cache_s(f,slot,10,key.ppem)
in () end
