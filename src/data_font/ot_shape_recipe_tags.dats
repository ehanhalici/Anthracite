#include "data_font/ot_shape_internal.hats"
fun composition(r: OtShapeRequest): string = case+ r.profile of
  | ShapeCommonHorizontal() => (case+ r.direction of
    | ShapeLTR() => "abvmblwmccmploclmarkmkmkrligcaltcligcursdistkernligarcltltraltrm"
    | ShapeRTL() => "abvmblwmccmploclmarkmkmkrligcaltcligcursdistkernligarcltrtlartlm")
  | ShapeArabicHorizontal() => (case+ r.direction of
    | ShapeLTR() => "ccmploclltraltrm" | ShapeRTL() => "ccmploclrtlartlm")
implement ot_shape_stage_tags(r,stage) = case+ stage of
  | ShapeVariation() => "rvrn" | ShapeComposition() => composition(r)
  | ShapeIsolated() => "isol" | ShapeFinal() => "fina" | ShapeMedial() => "medi" | ShapeInitial() => "init"
  | ShapeRequiredLigatures() => "rlig" | ShapeContextual() => "caltrclt"
  | ShapeStandard() => "abvmblwmmarkmkmkcligcursdistkernligamset"
  | ShapePositioning() => "abvmblwmccmploclmarkmkmkrligcaltcligcursdistkernligarcltmset"
