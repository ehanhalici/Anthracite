#include "data_font/font_text_internal.hats"
extern fun release_exhausted(slot: Option_vt(FontTextCache)): void = "mac#anth_die_void"
extern fun retain_exhausted(slot: Option_vt(FontTextCache)): Option_vt(FontTextCache) = "mac#anth_die_box"
fun release{n:nat} .<n>. (fuel: int(n),slot: Option_vt(FontTextCache)): void =
  if fuel > 0 then case+ slot of
    | ~None_vt() => ()
    | ~Some_vt(cache) => let val+ ~FontTextCache(key,layout,px,tail)=cache
      val ()=font_span_dispose(layout) val ()=buf_free(key)
    in release(fuel-1,tail) end
  else release_exhausted(slot)
implement font_text_cache_release(slot) = release(airlock_nat(MAX_REC_FUEL),slot)
fun retain{n:nat} .<n>. (fuel: int(n),slot: Option_vt(FontTextCache),count: int,budget: int): Option_vt(FontTextCache) =
  if fuel > 0 then case+ slot of
    | ~None_vt() => None_vt()
    | ~Some_vt(cache) => let val+ ~FontTextCache(key,layout,px,tail)=cache
      val size=buf_len(key)
    in if ile(count,0) orelse igt(size,budget) then let
      val ()=font_span_dispose(layout) val ()=buf_free(key) val ()=font_text_cache_release(tail)
    in None_vt() end else Some_vt(FontTextCache(key,layout,px,retain(fuel-1,tail,isub(count,1),isub(budget,size)))) end
  else retain_exhausted(slot)
implement font_text_cache_retain(slot,count,budget) = retain(airlock_nat(MAX_REC_FUEL),slot,count,budget)
