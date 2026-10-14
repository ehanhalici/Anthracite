#include "data_font/native_shape_internal.hats"
staload "data_text/normalization_types.sats"
staload "data_text/normalization_engine.sats"
staload "data_text/arabic_marks_types.sats"
staload "data_text/arabic_marks.sats"
staload "data_font/native_shape_text_work.sats"
fun arabic(b: !Buf,info: SfntInfo,n: !NormalizationData,mcm: !PropertyMap(9),source: !ScalarText,start: int,finish: int): NativeShapeTextRead =
  case+ arabic_marks_apply_range(n,mcm,source,start,finish) of | ~ArabicMarksRejected(e) => NativeTextRejected(e)
  | ~ArabicMarksReady(text) => NativeTextAccepted(NativeShapeText(native_shape_text_compose(b,info,n,text),ShapeArabicHorizontal()))
fun common(n: !NormalizationData,source: !ScalarText,start: int,finish: int): NativeShapeTextRead = case+ normalization_apply_range(n,source,start,finish,NFC()) of
  | ~CannotNormalize(e) => NativeTextRejected(e)
  | ~NormalizedText(text) => NativeTextAccepted(NativeShapeText(text,ShapeCommonHorizontal()))
implement native_shape_text_parse(b,info,plan,n,mcm,source) = native_shape_text_parse_range(b,info,plan,n,mcm,source,0,scalar_count(source))
implement native_shape_text_parse_range(b,info,plan,n,mcm,source,start,finish) = let val+ NativeShapePlan(sub,pos,p)=plan
in case+ p.request.profile of | ShapeCommonHorizontal() => common(n,source,start,finish)
  | ShapeArabicHorizontal() => arabic(b,info,n,mcm,source,start,finish) end
implement native_shape_text_dispose(text) = let val+ ~NativeShapeText(source,profile)=text in scalar_dispose(source) end
