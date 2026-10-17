#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/glyph/position/glyph_position_work.sats"
fun copy{n,m,k:nat} .<k>. (left: int(k),s: !GlyphStorage(n),cache: !GlyphPositionCache(m),i: int): void =
  if left = 0 then () else let val ()=glyph_position_cache_set(cache,i,glyph_storage_position(s,i)) in
    copy(left-1,s,cache,iadd(i,1)) end
fun commit{n,m,k:nat} .<k>. (left: int(k),cache: !GlyphPositionCache(n),s: !GlyphStorage(m),i: int): void =
  if left = 0 then () else let val ()=glyph_storage_set_position(s,i,glyph_position_cache_get(cache,i)) in
    commit(left-1,cache,s,iadd(i,1)) end
implement glyph_position_cache_copy(s,cache,count) = copy(airlock_nat(count),s,cache,0)
implement glyph_position_cache_commit(cache,s,count) = commit(airlock_nat(count),cache,s,0)
