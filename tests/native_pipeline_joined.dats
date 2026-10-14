#include "native_pipeline_test.hats"
staload "data_font/native_text_items_work.sats"
fun checked(run: GlyphPositioned(1)): int = let
  val meta=glyph_position_meta(run) val first=glyph_position_query(run,meta.head)
  val ok=ieq(meta.live,3) andalso ieq(first.core.glyph,16) andalso ieq(first.position.xAdvance,299)
    andalso ieq(first.core.sourceStart,4) andalso ieq(first.core.sourceEnd,6)
  val ()=glyph_position_dispose(run)
in if ok then 0 else 1 end
fun shaped(assets: !NativeTextAssets,a: !NativeTextAnalysis,contexts: !NativeTextContexts,
  arabic: !SfntFace,cache: !NativeShapeCache): int = let
  val+ SfntFace(b,info)=arabic val item=native_text_item_read(a,2,4)
  val masks: OtShapeMasks= @{initial=1u,medial=2u,final=4u,isolated=8u,mirror=16u}
in case+ native_text_item_shape(b,info,cache,assets,a,contexts,item,ShapeDefaultLanguage(),masks,@{xPpem=16,yPpem=16}) of
  | ~NativeItemShaped(run) => checked(run) | ~NativeItemUnsupported(s) => 1
  | ~NativeItemPlanError(e) => 1 | ~NativeItemTextError(e) => 1 | ~NativeItemRunError(e) => 1 end
fun analyzed(assets: !NativeTextAssets,a: NativeTextAnalysis,arabic: !SfntFace,cache: !NativeShapeCache): int = let
  val errors=case+ native_text_context_make(assets,a) of | ~NativeContextRejected(e) => 1
    | ~NativeContextAccepted(contexts) => let val result=shaped(assets,a,contexts,arabic,cache)
      val ()=native_text_context_dispose(contexts) in result end
  val ()=native_text_analysis_dispose(a)
in errors end
implement pipeline_joined_case(assets,arabic,cache) = let val bytes=pipeline_bytes("بَبَب")
  val errors=case+ native_text_analyze(assets,bytes,buf_len(bytes),AutoLtr()) of
    | ~NativeAnalysisRejected(e) => 1 | ~NativeAnalysisAccepted(a) => analyzed(assets,a,arabic,cache)
  val ()=buf_free(bytes)
in errors end
