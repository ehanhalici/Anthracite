#include "data_font/ot_shape_internal.hats"
fun arabic_stage_of(index: int): OtShapeStage = case+ index of
  | 0 => ShapeVariation() | 1 => ShapeComposition() | 2 => ShapeIsolated()
  | 3 => ShapeFinal() | 4 => ShapeMedial() | 5 => ShapeInitial()
  | 6 => ShapeRequiredLigatures() | 7 => ShapeContextual() | _ => ShapeStandard()
implement ot_shape_stage_count(domain,profile) = case+ domain of
  | OtPositioning() => 1 | OtSubstitution() => (case+ profile of
    | ShapeCommonHorizontal() => 2 | ShapeArabicHorizontal() => 9)
implement ot_shape_stage_of(domain,profile,index) = case+ domain of
  | OtPositioning() => ShapePositioning() | OtSubstitution() => (case+ profile of
    | ShapeCommonHorizontal() => if ieq(index,0) then ShapeVariation() else ShapeComposition()
    | ShapeArabicHorizontal() => arabic_stage_of(index))
fun stage_code(stage: OtShapeStage): int = case+ stage of
  | ShapeVariation() => 0 | ShapeComposition() => 1 | ShapeIsolated() => 2 | ShapeFinal() => 3
  | ShapeMedial() => 4 | ShapeInitial() => 5 | ShapeRequiredLigatures() => 6
  | ShapeContextual() => 7 | ShapeStandard() => 8 | ShapePositioning() => 9
implement ot_shape_stage_equal(a,b) = ieq(stage_code(a),stage_code(b))

