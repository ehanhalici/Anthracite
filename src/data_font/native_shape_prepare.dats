#include "data_font/native_shape_internal.hats"
extern fun native_shape_mask_failed(): ArabicMaskPlan = "mac#anth_die_box"
fun arabic(joining: !PropertyMap(3),m: OtShapeMasks,context: ArabicContext,run: GlyphRun(0)): GlyphRun(1) =
  case+ arabic_mask_plan(@{initial=m.initial,medial=m.medial,final=m.final,isolated=m.isolated}) of
  | ~ArabicMaskRejected(e) => let val masks=native_shape_mask_failed()
    val result=glyph_arabic_prepare(joining,masks,context,run) val ()=arabic_mask_dispose(masks) in result end
  | ~ArabicMaskAccepted(masks) => let val result=glyph_arabic_prepare(joining,masks,context,run)
    val ()=arabic_mask_dispose(masks) in result end
implement native_shape_prepare(data,plan,context,run) = let
  val+ NativeShapeData(db,category,ignored,joining)=data
  val+ NativeShapePlan(sub,pos,info)=plan
  val run=glyph_unicode_prepare(category,ignored,run)
in case+ info.request.profile of | ShapeCommonHorizontal() => glyph_run_substitute(run)
  | ShapeArabicHorizontal() => arabic(joining,info.masks,context,run) end
