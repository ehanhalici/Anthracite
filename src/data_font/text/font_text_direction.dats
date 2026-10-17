#include "data_font/text/font_text_internal.hats"
fun resolved{b:bool}(slot: !option_vt(FontTextCache,b)): FontTextResult = case+ slot of
  | None_vt() => FontTextFailed(SpanShaping()) | Some_vt(cache) => let val+ FontTextCache(key,layout,px,tail)=cache
    in FontTextValue(font_span_direction(layout)) end
fun active(f: !Font,session: &FontTextSession >> FontTextSession,b: !Buf,length: int): FontTextResult = let
  val+ ~FontTextSession(assets,old,primary,fallback,metrics)=session var cache: Option_vt(FontTextCache)=old val px=font_get_px(f)
  val options: FontSpanOptions= @{primary=primary,fallback=fallback,scale= @{xPpem=px,yPpem=px}}
  val prepared=font_text_cache_prepare(cache,f,assets,b,length,options)
  val result=(case+ prepared of | ~Some_vt(error) => FontTextFailed(error) | ~None_vt() => resolved(cache)): FontTextResult
  val ()=session := FontTextSession(assets,cache,primary,fallback,metrics)
in result end
fun direction(f: !Font,state: &Option_vt(FontTextSession) >> _,b: !Buf,length: int): FontTextResult = case+ state of
  | @None_vt() => let prval ()=fold@(state) in FontTextInactive() end
  | @Some_vt(session) => let val result=active(f,session,b,length) prval ()=fold@(state) in result end
implement font_text_direction_code(f,b,length) = let var state=font_text_take(f)
  val result=direction(f,state,b,length) val ()=font_text_put(f,state)
in result end
