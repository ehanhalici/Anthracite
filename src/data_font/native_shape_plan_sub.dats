#include "data_font/native_shape_internal.hats"
implement native_shape_sub_plan(b,t,info) = case+ t of
  | NativeSubMissing() => (case+ info.request.profile of
    | ShapeCommonHorizontal() => NativeSubPlanAccepted(NativeSubNoPlan())
    | ShapeArabicHorizontal() => NativeSubPlanRejected(ot_error(OtUnsupported(),@{offset=0,length=0})))
  | NativeSubTables(table,g) => (case+ ot_shape_schedule_parse(b,table,OtSubstitution(),info.request,info.masks,info.face.font,info.face.glyphs) of
    | ~ShapeRejected(e) => NativeSubPlanRejected(e)
    | ~ShapeAccepted(s) => NativeSubPlanAccepted(NativeSubPlan(s)))
implement native_shape_sub_plan_dispose(t) = case+ t of | ~NativeSubNoPlan() => ()
  | ~NativeSubPlan(s) => ot_shape_schedule_dispose(s)

