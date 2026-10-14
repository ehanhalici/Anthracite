#include "native_pipeline_test.hats"
staload "opentype_fixture.sats"
fun expected(row: NativeTextItem): string = if ieq(row.level,0) then
  "0120 0269 0000 0000 0003 0269 0000 0000 00F2 0269 0000 0000 0003 0269 0000 0000" else
  "000E 0317 0000 0000 0141 0000 013B FFE0 0174 0000 011E FEEC 017A 0000 0110 FF53"
fun signed(value: int): int = if ige(value,32768) then isub(value,65536) else value
fun matches(run: !GlyphPositioned(1),node: int,words: !Buf,index: int,item: NativeTextItem): bool = let
  val v=glyph_position_query(run,node) val at=imul(index,8)
in ieq(v.core.glyph,ot_fixture_read16(words,at)) andalso ieq(v.position.xAdvance,ot_fixture_read16(words,iadd(at,2)))
  andalso ieq(v.position.xOffset,signed(ot_fixture_read16(words,iadd(at,4))))
  andalso ieq(v.position.yOffset,signed(ot_fixture_read16(words,iadd(at,6))))
  andalso ige(v.core.sourceStart,item.sourceStart) andalso ile(v.core.sourceEnd,item.sourceEnd) end
fun rows{n:nat} .<n>. (left: int(n),run: !GlyphPositioned(1),words: !Buf,index: int,node: int,item: NativeTextItem): bool =
  if left = 0 then ieq(node,~1) else let val v=glyph_position_query(run,node)
  in matches(run,node,words,index,item) andalso rows(left-1,run,words,iadd(index,1),v.links.next,item) end
fun checked(run: GlyphPositioned(1),item: NativeTextItem): int = let
  val words=ot_fixture_words(expected(item)) val meta=glyph_position_meta(run)
  val ok=ieq(meta.live,4) andalso rows(4,run,words,0,meta.head,item)
  val ()=glyph_position_dispose(run) and ()=buf_free(words)
in if ok then 0 else 1 end
fun shaped(assets: !NativeTextAssets,a: !NativeTextAnalysis,contexts: !NativeTextContexts,
  face: !SfntFace,cache: !NativeShapeCache,item: NativeTextItem): int = let val+ SfntFace(b,info)=face
  val masks: OtShapeMasks= @{initial=1u,medial=2u,final=4u,isolated=8u,mirror=16u}
in case+ native_text_item_shape(b,info,cache,assets,a,contexts,item,ShapeDefaultLanguage(),masks,@{xPpem=16,yPpem=16}) of
  | ~NativeItemUnsupported(s) => 1 | ~NativeItemPlanError(e) => 1 | ~NativeItemTextError(e) => 1
  | ~NativeItemRunError(e) => 1 | ~NativeItemShaped(run) => checked(run,item) end
fun itemized(assets: !NativeTextAssets,a: !NativeTextAnalysis,contexts: !NativeTextContexts,
  latin: !SfntFace,lc: !NativeShapeCache,arabic: !SfntFace,ac: !NativeShapeCache): int =
  case+ native_text_items_make(a) of | ~NativeItemsRejected(e) => 1 | ~NativeItemsAccepted(items) => let
    val errors=if ine(native_text_items_count(items),2) then 1 else
      shaped(assets,a,contexts,latin,lc,native_text_items_at(items,0))
      +shaped(assets,a,contexts,arabic,ac,native_text_items_at(items,1))
    val ()=native_text_items_dispose(items)
  in errors end
fun analyzed(assets: !NativeTextAssets,a: NativeTextAnalysis,latin: !SfntFace,lc: !NativeShapeCache,
  arabic: !SfntFace,ac: !NativeShapeCache): int = let
  val errors=case+ native_text_context_make(assets,a) of | ~NativeContextRejected(e) => 1
    | ~NativeContextAccepted(contexts) => let val result=itemized(assets,a,contexts,latin,lc,arabic,ac)
      val ()=native_text_context_dispose(contexts) in result end
  val ()=native_text_analysis_dispose(a)
in errors end
fun cached(assets: !NativeTextAssets,latin: !SfntFace,lc: !NativeShapeCache,arabic: !SfntFace): int = let
  val+ SfntFace(b,info)=arabic
in case+ native_shape_cache_parse(b,info,2) of | ~NativeCacheRejected(e) => 1 | ~NativeCacheAccepted(ac) => let
    val bytes=pipeline_bytes("Ş İ بَّ")
    val errors=case+ native_text_analyze(assets,bytes,buf_len(bytes),AutoLtr()) of
      | ~NativeAnalysisRejected(e) => 1 | ~NativeAnalysisAccepted(a) => analyzed(assets,a,latin,lc,arabic,ac)
    val joined=pipeline_joined_case(assets,arabic,ac)
    val ()=buf_free(bytes) and ()=native_shape_cache_dispose(ac)
  in iadd(errors,joined) end end
implement pipeline_shape_cases(assets,latin,arabic) = let val+ SfntFace(b,info)=latin
in case+ native_shape_cache_parse(b,info,1) of | ~NativeCacheRejected(e) => 1 | ~NativeCacheAccepted(lc) => let
    val errors=cached(assets,latin,lc,arabic) val ()=native_shape_cache_dispose(lc)
  in errors end end
