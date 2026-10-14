#include "data_font/font_text_internal.hats"
fun fresh(slot: &Option_vt(FontTextCache) >> Option_vt(FontTextCache),f: !Font,assets: !NativeTextAssets,
  b: !Buf,length: int,options: FontSpanOptions): Option_vt(FontSpanFailure) =
  case+ font_span_make(f,assets,b,length,options) of
  | ~FontSpanRejected(error) => Some_vt(error)
  | ~FontSpanAccepted(layout) => let var key=buf_make(length)
    val ()=buf_append_at(key,b,0,length)
    val old=slot
    val tail=font_text_cache_retain(old,127,isub(262144,length))
    val ()=slot := Some_vt(FontTextCache(key,layout,options.scale.yPpem,tail))
  in None_vt() end
fun selected(slot: &Option_vt(FontTextCache) >> Option_vt(FontTextCache),f: !Font,assets: !NativeTextAssets,
  b: !Buf,length: int,options: FontSpanOptions): Option_vt(FontSpanFailure) = let
  val old=slot
  val (hit,rest)=font_text_cache_select(old,f,b,length,options.scale.yPpem)
in case+ hit of
  | ~None_vt() => let val ()=slot := rest in fresh(slot,f,assets,b,length,options) end
  | ~Some_vt(cache) => let val+ ~FontTextCache(key,layout,px,tail)=cache
    val ()=font_text_cache_release(tail)
    val ()=slot := Some_vt(FontTextCache(key,layout,px,rest))
  in None_vt() end end
fun head{a:bool}(slot: !option_vt(FontTextCache,a),f: !Font,b: !Buf,length: int,px: int): bool = case+ slot of
  | None_vt() => false | Some_vt(cache) => font_text_cache_matches(cache,f,b,length,px)
implement font_text_cache_prepare(slot,f,assets,b,length,options) =
  if ilt(length,0) orelse igt(length,buf_cap(b)) then Some_vt(SpanAnalysis())
  else if head(slot,f,b,length,options.scale.yPpem) then None_vt()
  else selected(slot,f,assets,b,length,options)
