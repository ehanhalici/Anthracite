#include "native_pipeline_test.hats"
datatype BoundaryExpected = ExpectNone | ExpectDual | ExpectCausing
fun matches(b: ArabicBoundary,e: BoundaryExpected): bool = case+ b of
  | BoundaryNone() => (case+ e of | ExpectNone() => true | ExpectDual() => false | ExpectCausing() => false)
  | BoundaryDual() => (case+ e of | ExpectNone() => false | ExpectDual() => true | ExpectCausing() => false)
  | BoundaryCausing() => (case+ e of | ExpectNone() => false | ExpectDual() => false | ExpectCausing() => true)
  | BoundaryRight() => false | BoundaryLeft() => false
fun examined(assets: !NativeTextAssets,a: NativeTextAnalysis,start: int,finish: int,
  before: BoundaryExpected,after: BoundaryExpected): int = let
  val errors=case+ native_text_context_make(assets,a) of | ~NativeContextRejected(e) => 1
    | ~NativeContextAccepted(contexts) => let val c=native_text_context_at(contexts,start,finish)
      val ok=matches(c.before,before) andalso matches(c.after,after)
      val ()=native_text_context_dispose(contexts) in if ok then 0 else 1 end
  val ()=native_text_analysis_dispose(a)
in errors end
fun check(assets: !NativeTextAssets,source: string,start: int,finish: int,
  before: BoundaryExpected,after: BoundaryExpected): int = let val bytes=pipeline_bytes(source)
  val errors=case+ native_text_analyze(assets,bytes,buf_len(bytes),AutoLtr()) of
    | ~NativeAnalysisRejected(e) => 1 | ~NativeAnalysisAccepted(a) => examined(assets,a,start,finish,before,after)
  val ()=buf_free(bytes)
in errors end
implement pipeline_context_cases(assets) = check(assets,"بَبَب",2,4,ExpectDual(),ExpectDual())
  +check(assets,"ب\nب",2,3,ExpectNone(),ExpectNone())+check(assets,"ب\r\nب",3,4,ExpectNone(),ExpectNone())
  +check(assets,"ب‌ب",2,3,ExpectNone(),ExpectNone())+check(assets,"ب‍ب",2,3,ExpectCausing(),ExpectNone())
  +check(assets,"",0,0,ExpectNone(),ExpectNone())
