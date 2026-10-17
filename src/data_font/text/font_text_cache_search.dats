#include "data_font/text/font_text_internal.hats"
extern fun exhausted(slot: Option_vt(FontTextCache)): Option_vt(FontTextCache) = "mac#anth_die_box"
extern fun search_exhausted(): int = "mac#anth_die_int"
fun locate{n:nat}{a:bool} .<n>. (fuel: int(n),slot: !option_vt(FontTextCache,a),f: !Font,b: !Buf,length: int,px: int,i: int): int =
  if fuel > 0 then case+ slot of
    | None_vt() => ~1 | Some_vt(cache) =>
      if font_text_cache_matches(cache,f,b,length,px) then i else let
        val+ FontTextCache(key,layout,size,tail)=cache
      in locate(fuel-1,tail,f,b,length,px,iadd(i,1)) end
  else search_exhausted()
fun select{n:nat} .<n>. (fuel: int(n),slot: Option_vt(FontTextCache),f: !Font,b: !Buf,length: int,px: int):
  @(Option_vt(FontTextCache),Option_vt(FontTextCache)) =
  if fuel > 0 then case+ slot of
    | ~None_vt() => (None_vt(),None_vt())
    | ~Some_vt(cache) => let
      val hit=font_text_cache_matches(cache,f,b,length,px)
      val+ ~FontTextCache(key,layout,size,tail)=cache
    in if hit then (Some_vt(FontTextCache(key,layout,size,None_vt())),tail)
      else let val (found,rest)=select(fuel-1,tail,f,b,length,px)
      in (found,Some_vt(FontTextCache(key,layout,size,rest))) end end
  else (None_vt(),exhausted(slot))
implement font_text_cache_select(slot,f,b,length,px) =
  if ilt(locate(airlock_nat(MAX_REC_FUEL),slot,f,b,length,px,0),0) then (None_vt(),slot)
  else select(airlock_nat(MAX_REC_FUEL),slot,f,b,length,px)
