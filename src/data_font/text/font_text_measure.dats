#include "data_font/text/font_text_internal.hats"
staload "core_runtime/performance.sats"
fun pixels(value: int): int = iadd(idiv(value,64),if ieq(imod(value,64),0) then 0 else 1)
fun measured{b:bool}(slot: !option_vt(FontTextCache,b)): FontTextResult = case+ slot of
  | None_vt() => FontTextFailed(SpanShaping())
  | Some_vt(cache) => let val+ FontTextCache(key,layout,px,tail)=cache
    in FontTextValue(pixels(font_span_width(layout))) end
fun remember(result: FontTextResult,metrics: &FontTextMetrics >> FontTextMetrics,f: !Font,b: !Buf,n: int,px: int): void =
  case+ result of | FontTextValue(value) => font_text_metrics_insert(metrics,f,b,n,px,value)
    | FontTextFailed(error) => () | FontTextInactive() => ()
fun miss(f: !Font,assets: !NativeTextAssets,cache: &Option_vt(FontTextCache) >> _,
  metrics: &FontTextMetrics >> FontTextMetrics,b: !Buf,length: int,options: FontSpanOptions): FontTextResult = let
  val prepared=font_text_cache_prepare(cache,f,assets,b,length,options)
  val result=case+ prepared of
    | ~Some_vt(error) => FontTextFailed(error) | ~None_vt() => measured(cache)
  val ()=remember(result,metrics,f,b,length,options.scale.yPpem)
in result end
fun active(f: !Font,session: &FontTextSession >> FontTextSession,b: !Buf,length: int): FontTextResult = let
  val+ ~FontTextSession(assets,old,primary,fallback,m)=session
  var cache: Option_vt(FontTextCache)=old var metrics: FontTextMetrics=m val px=font_get_px(f)
  val options: FontSpanOptions= @{primary=primary,fallback=fallback,scale= @{xPpem=px,yPpem=px}}
  val result=case+ font_text_metrics_lookup(metrics,f,b,length,px) of
    | Some(value) => FontTextValue(value) | None() => miss(f,assets,cache,metrics,b,length,options)
  val ()=session := FontTextSession(assets,cache,primary,fallback,metrics)
in result end
fun session_width(f: !Font,state: &Option_vt(FontTextSession) >> _,b: !Buf,length: int): FontTextResult = case+ state of
  | @None_vt() => let prval ()=fold@(state) in FontTextInactive() end
  | @Some_vt(session) => let val result=active(f,session,b,length) prval ()=fold@(state) in result end
implement font_text_width(f,b,length) = let var state=font_text_take(f)
  val ()=performance_note(PERF_WIDTH_QUERIES,1)
  val result=session_width(f,state,b,length) val ()=font_text_put(f,state)
in result end
