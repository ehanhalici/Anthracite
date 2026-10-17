#include "data_font/text/font_text_internal.hats"
fun selected_plan(hit: Option_vt(FontTextCache),f: !Font,assets: !NativeTextAssets,
  source: !Buf,length: int,options: FontSpanOptions): FontSpanRead = case+ hit of
  | ~None_vt() => font_span_make(f,assets,source,length,options)
  | ~Some_vt(cache) => let val+ ~FontTextCache(key,layout,px,tail)=cache
    val ()=buf_free(key) val ()=font_text_cache_release(tail)
  in FontSpanAccepted(layout) end
fun session_plan(f: !Font,session: &FontTextSession >> _,source: !Buf,length: int): FontSpanRead = let
  val+ ~FontTextSession(assets,cache,primary,fallback,metrics)=session val px=font_get_px(f)
  val options: FontSpanOptions= @{primary=primary,fallback=fallback,scale= @{xPpem=px,yPpem=px}}
  val (hit,remaining)=font_text_cache_select(cache,f,source,length,px)
  val result=selected_plan(hit,f,assets,source,length,options)
  val ()=session := FontTextSession(assets,remaining,primary,fallback,metrics)
in result end
fun dispatch(f: !Font,state: &Option_vt(FontTextSession) >> _,source: !Buf,length: int): FontSpanRead = case+ state of
  | @None_vt() => let prval ()=fold@(state) in FontSpanRejected(SpanContext()) end
  | @Some_vt(session) => let val result=session_plan(f,session,source,length) prval ()=fold@(state) in result end
implement font_text_row_plan(f,source,length) = let var state=font_text_take(f)
  val result=dispatch(f,state,source,length) val ()=font_text_put(f,state)
in result end
