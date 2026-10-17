#include "data_font/text/font_text_internal.hats"
staload "data_font/native/text/native_text_analysis.sats"
staload "data_font/native/text/native_text_analysis_types.sats"
staload "data_text/bidi/bidi_types.sats"
fun analyze{b:bool}(state: !option_vt(FontTextSession,b),source: !Buf,length: int): NativeAnalysisRead = case+ state of
  | None_vt() => NativeAnalysisRejected(@{reason=AnalysisSpan(),detail=length})
  | Some_vt(session) => let val+ FontTextSession(assets,cache,p,a,m)=session
    in native_text_analyze(assets,source,length,AutoLtr()) end
implement font_text_paragraph_analysis(f,source,length) = let val state=font_text_take(f)
  val result=analyze(state,source,length) val ()=font_text_put(f,state)
in result end
fun shaped(f: !Font,assets: !NativeTextAssets,parent: !NativeTextAnalysis,start: int,finish: int,options: FontSpanOptions): FontSpanRead =
  case+ native_text_analysis_window(parent,start,finish) of
  | ~NativeAnalysisRejected(error) => FontSpanRejected(SpanParagraph())
  | ~NativeAnalysisAccepted(window) => font_span_from_analysis(f,assets,window,isub(finish,start),options)
fun line{b:bool}(f: !Font,state: !option_vt(FontTextSession,b),parent: !NativeTextAnalysis,start: int,finish: int): FontSpanRead = case+ state of
  | None_vt() => FontSpanRejected(SpanContext()) | Some_vt(session) => let
    val+ FontTextSession(assets,cache,primary,fallback,metrics)=session val px=font_get_px(f)
    val options: FontSpanOptions= @{primary=primary,fallback=fallback,scale= @{xPpem=px,yPpem=px}}
  in shaped(f,assets,parent,start,finish,options) end
implement font_text_line_plan(f,parent,start,finish) = let val state=font_text_take(f)
  val result=line(f,state,parent,start,finish) val ()=font_text_put(f,state)
in result end
