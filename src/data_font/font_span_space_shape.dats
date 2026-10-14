#include "data_font/font_span_internal.hats"
staload "data_font/native_text_items_work.sats"
fun contextual(f: !Font,assets: !NativeTextAssets,a: NativeTextAnalysis,options: FontSpanOptions): FontNativeRead =
  case+ native_text_context_make(assets,a) of
  | ~NativeContextRejected(error) => let val ()=native_text_analysis_dispose(a) in FontNativeNoFace() end
  | ~NativeContextAccepted(contexts) => let
    val item=native_text_item_read(a,0,1) val result=font_span_shape(f,assets,a,contexts,item,options)
    val ()=native_text_context_dispose(contexts) val ()=native_text_analysis_dispose(a)
  in result end
implement font_span_space_shape(f,assets,options) = let
  val b=buf_make(1) val ()=buf_set(b,0,32)
  val result=native_text_analyze(assets,b,1,AutoLtr()) val ()=buf_free(b)
in case+ result of | ~NativeAnalysisRejected(error) => FontNativeNoFace()
  | ~NativeAnalysisAccepted(a) => contextual(f,assets,a,options) end
