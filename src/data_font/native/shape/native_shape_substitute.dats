#include "data_font/native/shape/native_shape_internal.hats"
implement native_shape_substitute(b,cache,plan,run) = let
  val+ NativeShapeCache(m,sub,pos,face)=cache val+ NativeShapePlan(selected,positions,info)=plan
in case+ selected of
  | NativeSubNoPlan() => SubStageResult(run,GlyphPassApplied(),0,0)
  | NativeSubPlan(s) => (case+ sub of
    | NativeSubMissing() => SubStageResult(run,GlyphPassReference(),0,0)
    | NativeSubTables(table,g) => glyph_substitution_schedule_apply(b,g,s,m,run)) end
implement native_shape_position(b,cache,plan,p) = let
  val+ NativeShapeCache(m,sub,pos,face)=cache val+ NativeShapePlan(selected,positions,info)=plan
in case+ positions of
  | NativePosNoPlan() => PositionStageResult(p,PositionReady(),0,0)
  | NativePosPlan(s) => (case+ pos of
    | NativePosMissing() => PositionStageResult(p,PositionReference(),0,0)
    | NativePosTables(table,g) => glyph_position_schedule_apply(b,g,s,m,p,native_shape_direction(info.request))) end
implement native_shape_direction(r) = case+ r.direction of | ShapeLTR() => PositionLTR() | ShapeRTL() => PositionRTL()
implement native_shape_error(reason) = @{reason=reason,edit=GlyphUnchanged(),substitution=GlyphPassApplied(),position=PositionReady()}
implement native_shape_profile_equal(a,b) = case+ a of
  | ShapeCommonHorizontal() => (case+ b of | ShapeCommonHorizontal() => true | ShapeArabicHorizontal() => false)
  | ShapeArabicHorizontal() => (case+ b of | ShapeCommonHorizontal() => false | ShapeArabicHorizontal() => true)
