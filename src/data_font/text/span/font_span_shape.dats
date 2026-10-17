#include "data_font/text/span/font_span_internal.hats"
staload "data_font/text/span/private/font_span_partition.sats"
fun on_face(f: !Font,assets: !NativeTextAssets,a: !NativeTextAnalysis,c: !NativeTextContexts,
  item: NativeTextItem,options: FontSpanOptions,face: FontGlyphFace): FontNativeRead = let
  val masks: OtShapeMasks= @{initial=1u,medial=2u,final=4u,isolated=8u,mirror=16u}
  val id=case+ face of | GlyphPrimaryFace() => options.primary | GlyphFallbackFace() => options.fallback
in font_shape_native_item(f,assets,a,c,item,face,id,ShapeDefaultLanguage(),masks,options.scale) end
implement font_span_shape(f,assets,a,c,item,options) = case+ font_span_candidate(f,assets,a,item) of
  | SpanPrimaryCandidate() => on_face(f,assets,a,c,item,options,GlyphPrimaryFace())
  | SpanFallbackCandidate() => on_face(f,assets,a,c,item,options,GlyphFallbackFace())
  | SpanMissingCandidate() => FontNativeNoFace()
  | SpanTabCandidate() => FontNativeNoFace()
  | SpanLineEndCandidate() => FontNativeNoFace()
