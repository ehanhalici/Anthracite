#include "data_font/text/span/font_span_internal.hats"
staload "core_runtime/performance.sats"
staload "data_font/text/span/private/font_span_partition.sats"
fun allocated(f: !Font,assets: !NativeTextAssets,a: NativeTextAnalysis,contexts: !NativeTextContexts,
  items: NativeTextItems,options: FontSpanOptions): FontSpanRead = let
  val n=airlock_nat(native_text_items_count(items)) val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes,source_length)=a
  val base=if ieq(scalar_count(text),0) then 0 else bidi_document_base(bidi,0)
  val empty: FontSpanPart= @{kind=SpanTextPart(),start=0,finish=0,sourceStart=0,sourceEnd=0,level=0,width=0,x=0}
  val layout=FontSpanLayout(a,items,font_span_runs_make(n),arrayptr_make_elt<FontSpanPart>(i2sz(n),empty),
    buf_make(imul(n,4)),n,0,base)
  val+ FontSpanLayout(analysis,parts,runs,rows,order,count,width,direction)=layout
in case+ font_span_fill(f,assets,analysis,contexts,layout,options) of
  | ~Some_vt(error) => let val ()=font_span_dispose(layout) in FontSpanRejected(error) end
  | ~None_vt() => (case+ font_span_total(layout) of
    | ~None_vt() => let val ()=font_span_dispose(layout) in FontSpanRejected(SpanOverflow()) end
    | ~Some_vt(total) => let val ()=font_span_order(assets,layout) in FontSpanAccepted(layout) end) end
fun itemized(f: !Font,assets: !NativeTextAssets,a: NativeTextAnalysis,contexts: !NativeTextContexts,
  options: FontSpanOptions): FontSpanRead = case+ font_span_items_make(f,assets,a) of
  | ~NativeItemsRejected(e) => let val ()=native_text_analysis_dispose(a) in FontSpanRejected(SpanItems()) end
  | ~NativeItemsAccepted(items) => if igt(native_text_items_count(items),idiv(MAX_REC_FUEL,128)) then let
    val ()=native_text_items_dispose(items) and ()=native_text_analysis_dispose(a)
    in FontSpanRejected(SpanCapacity()) end else allocated(f,assets,a,contexts,items,options)
fun contextual(f: !Font,assets: !NativeTextAssets,a: NativeTextAnalysis,options: FontSpanOptions): FontSpanRead =
  case+ native_text_context_make(assets,a) of
  | ~NativeContextRejected(e) => let val ()=native_text_analysis_dispose(a) in FontSpanRejected(SpanContext()) end
  | ~NativeContextAccepted(contexts) => let val result=itemized(f,assets,a,contexts,options)
    val ()=native_text_context_dispose(contexts) in result end
fun paragraph(f: !Font,assets: !NativeTextAssets,a: NativeTextAnalysis,options: FontSpanOptions): FontSpanRead = let
  val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes,source_length)=a val n=scalar_count(text)
  val single=ieq(n,0) orelse ieq(bidi_document_paragraph_end(bidi,0),n)
in if single then contextual(f,assets,a,options) else let val ()=native_text_analysis_dispose(a)
  in FontSpanRejected(SpanParagraph()) end end
implement font_span_make(f,assets,source,length,options) = let
  val ()=performance_note(PERF_SHAPE_CALLS,1)
  val ()=performance_note(PERF_SHAPED_BYTES,length)
in case+ native_text_analyze(assets,source,length,AutoLtr()) of
  | ~NativeAnalysisRejected(e) => FontSpanRejected(SpanAnalysis())
  | ~NativeAnalysisAccepted(a) => paragraph(f,assets,a,options)
end
implement font_span_from_analysis(f,assets,analysis,length,options) = let
  val ()=performance_note(PERF_SHAPE_CALLS,1) val ()=performance_note(PERF_SHAPED_BYTES,length)
in paragraph(f,assets,analysis,options) end
