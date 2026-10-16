#include "data_font/native/shape/native_shape_internal.hats"
implement native_shape_pos_plan(b,t,info) = case+ t of
  | NativePosMissing() => NativePosPlanAccepted(NativePosNoPlan())
  | NativePosTables(table,g) => (case+ ot_shape_schedule_parse(b,table,OtPositioning(),info.request,info.masks,info.face.font,info.face.glyphs) of
    | ~ShapeRejected(e) => NativePosPlanRejected(e)
    | ~ShapeAccepted(s) => NativePosPlanAccepted(NativePosPlan(s)))
implement native_shape_pos_plan_dispose(t) = case+ t of | ~NativePosNoPlan() => ()
  | ~NativePosPlan(s) => ot_shape_schedule_dispose(s)
