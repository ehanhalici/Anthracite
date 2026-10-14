#include "font_native_test.hats"
fun copy{n:nat} .<n>. (left: int(n),s: string,b: !Buf,index: int): void = if left = 0 then () else let
  val ()=buf_set(b,index,c_str_byte(s,index)) in copy(left-1,s,b,iadd(index,1)) end
fun itemized(r: !Rend,assets: !NativeTextAssets,a: !NativeTextAnalysis,contexts: !NativeTextContexts): int =
  case+ native_text_items_make(a) of | ~NativeItemsRejected(e) => 1 | ~NativeItemsAccepted(items) => let
    val errors=if ine(native_text_items_count(items),2) then 1 else native_font_cases(r,assets,a,contexts,items)
    val ()=native_text_items_dispose(items) in errors end
fun analyzed(r: !Rend,assets: !NativeTextAssets,a: NativeTextAnalysis): int = let
  val errors=case+ native_text_context_make(assets,a) of | ~NativeContextRejected(e) => 1
    | ~NativeContextAccepted(contexts) => let val result=itemized(r,assets,a,contexts)
      val ()=native_text_context_dispose(contexts) in result end
  val ()=native_text_analysis_dispose(a)
in errors end
fun loaded(r: !Rend,assets: !NativeTextAssets): int = let val text="Ş İ بَّ" val size=c_strlen(text)
  val b=buf_make(size) val ()=copy(airlock_nat(size),text,b,0) val ()=buf_set_len(b,size)
  val errors=case+ native_text_analyze(assets,b,size,AutoLtr()) of
    | ~NativeAnalysisRejected(e) => 1 | ~NativeAnalysisAccepted(a) => analyzed(r,assets,a)
  val ()=buf_free(b)
in errors end
implement native_font_suite(r) = if ine(c_argc(),7) then 0 else
  case+ native_text_assets_load(@{generated=c_argv(5),source=c_argv(6)}) of
  | ~NativeAssetsRejected(e) => 1 | ~NativeAssetsAccepted(assets) => let
    val errors=iadd(iadd(iadd(loaded(r,assets),native_span_cases(r,assets)),native_span_boundary_cases(r,assets)),
      iadd(iadd(iadd(native_text_service_cases(r),native_span_partition_cases(r,assets)),native_workspace_startup_case(r)),
        iadd(iadd(native_span_missing_cases(r,assets),native_doc_navigation_cases()),native_font_registry_cases())))
    val ()=native_text_assets_dispose(assets)
    val ()=println!("event=native_font_owner errors=",errors)
  in errors end
