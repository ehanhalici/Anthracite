#include "data_font/font_text_internal.hats"
staload "data_font/private/font_text_dispatch.sats"
fun pixels(value: int): int = iadd(idiv(value,64),if ieq(imod(value,64),0) then 0 else 1)
fun raster_status_code(s: FontRunStatus): int = case+ s of
  | FontRunReady() => 0 | FontRunFace() => 1 | FontRunScale() => 2 | FontRunOverflow() => 3
  | FontRunRaster() => 4 | FontRunGraph() => 5
fun status(s: FontRunStatus,width: int): FontTextResult = let val code=raster_status_code(s)
  val ()=if ine(code,0) then println!("event=native_span_raster reason_code=",code) else ()
in case+ s of
  | FontRunReady() => FontTextValue(width)
  | FontRunFace() => FontTextFailed(SpanShaping()) | FontRunScale() => FontTextFailed(SpanShaping())
  | FontRunOverflow() => FontTextFailed(SpanOverflow()) | FontRunRaster() => FontTextFailed(SpanShaping())
  | FontRunGraph() => FontTextFailed(SpanShaping()) end
fun rendered{b:bool}(f: !Font,r: !Rend,slot: !option_vt(FontTextCache,b),x: double,y: double,color: uint): FontTextResult = case+ slot of
  | None_vt() => FontTextFailed(SpanShaping()) | Some_vt(cache) => let val+ FontTextCache(key,layout,px,tail)=cache
    val outcome=font_span_draw(f,r,layout,x,y,color)
  in status(outcome,pixels(font_span_width(layout))) end
fun active(f: !Font,r: !Rend,session: &FontTextSession >> FontTextSession,b: !Buf,length: int,x: double,y: double,color: uint): FontTextResult = let
  val+ ~FontTextSession(assets,old,primary,fallback,metrics)=session var cache: Option_vt(FontTextCache)=old val px=f_get_px(f)
  val options: FontSpanOptions= @{primary=primary,fallback=fallback,scale= @{xPpem=px,yPpem=px}}
  val prepared=font_text_cache_prepare(cache,f,assets,b,length,options)
  val result=case+ prepared of
    | ~Some_vt(error) => FontTextFailed(error) | ~None_vt() => rendered(f,r,cache,x,y,color)
  val ()=session := FontTextSession(assets,cache,primary,fallback,metrics)
in result end
fun session_draw(f: !Font,r: !Rend,state: &Option_vt(FontTextSession) >> _,b: !Buf,length: int,x: double,y: double,color: uint): FontTextResult =
  case+ state of | @None_vt() => let prval ()=fold@(state) in FontTextInactive() end
    | @Some_vt(session) => let val result=active(f,r,session,b,length,x,y,color) prval ()=fold@(state) in result end
implement font_text_draw_baseline(f,r,b,length,x,y,color) = let var state=font_text_take(f)
  val result=session_draw(f,r,state,b,length,x,y,color) val ()=font_text_put(f,state)
in result end
implement font_text_draw(f,r,b,length,x,y,color) =
  font_text_draw_baseline(f,r,b,length,n_i2d(x),n_i2d(y)+n_i2d(font_asc(f)),color)
