#include "data_font/font_text_internal.hats"
staload "data_font/font_paint.sats"
staload "data_font/font_text_paint.sats"
staload "data_font/font_document_metrics.sats"
fun pixels(value: int): int = iadd(idiv(value,64),if ieq(imod(value,64),0) then 0 else 1)
fun painted{b:bool}(slot: !option_vt(FontTextCache,b),f: !Font,r: !Rend,paint: TextPaint,x: int,y: int,c: uint): FontTextResult =
  case+ slot of | None_vt() => FontTextFailed(SpanShaping()) | Some_vt(cache) => let val+ FontTextCache(key,layout,px,tail)=cache
    val metrics=font_document_metrics(f)
    val baseline=case+ paint of | PaintGlyphs(range) => iadd(y,metrics.ascent) | PaintSelection(range,h) => y
    val status=font_span_paint(f,r,layout,paint,n_i2d(x),n_i2d(baseline),c)
  in case+ status of | FontRunReady() => FontTextValue(pixels(font_span_width(layout)))
    | FontRunFace() => FontTextFailed(SpanShaping()) | FontRunScale() => FontTextFailed(SpanShaping())
    | FontRunOverflow() => FontTextFailed(SpanOverflow()) | FontRunRaster() => FontTextFailed(SpanShaping())
    | FontRunGraph() => FontTextFailed(SpanShaping()) end
fun active(f: !Font,r: !Rend,session: &FontTextSession >> FontTextSession,b: !Buf,n: int,paint: TextPaint,x: int,y: int,c: uint): FontTextResult = let
  val+ ~FontTextSession(assets,old,p,a,m)=session var cache: Option_vt(FontTextCache)=old val px=f_get_px(f)
  val options: FontSpanOptions= @{primary=p,fallback=a,scale= @{xPpem=px,yPpem=px}}
  val result=case+ font_text_cache_prepare(cache,f,assets,b,n,options) of
    | ~Some_vt(e) => FontTextFailed(e) | ~None_vt() => painted(cache,f,r,paint,x,y,c)
  val ()=session := FontTextSession(assets,cache,p,a,m)
in result end
fun dispatch{b:bool}(state: &option_vt(FontTextSession,b) >> option_vt(FontTextSession,b),f: !Font,r: !Rend,
  source: !Buf,n: int,paint: TextPaint,x: int,y: int,c: uint): FontTextResult = case+ state of
  | @None_vt() => let prval ()=fold@(state) in FontTextInactive() end
  | @Some_vt(session) => let val result=active(f,r,session,source,n,paint,x,y,c) prval ()=fold@(state) in result end
implement font_text_paint(f,r,b,n,paint,x,y,c) = let var state=font_text_take(f)
  val result=dispatch(state,f,r,b,n,paint,x,y,c) val ()=font_text_put(f,state)
in result end
