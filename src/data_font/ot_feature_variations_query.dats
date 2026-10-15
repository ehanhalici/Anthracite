#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_features.sats"
staload "data_font/ot_feature_variations_types.sats"
staload "data_font/ot_feature_variations.sats"

fun missing_child(): OtChild =
  @{kind=ChildMissing(), span= @{offset=0, length=0}}

fun find_active {n:nat} .<n>. (
  n: int(n), b: !Buf, span: OtSpan, count: int, coords: !Buf, axisCount: int, i: int
): OtChild =
  if n = 0 then missing_child() else let
    val at = iadd(8, imul(i, 8))
    val floor = iadd(8, imul(count, 8))
    val csetOff = ot_u32(b, span, at)
    val substOff = ot_u32(b, span, iadd(at, 4))
    val cset = ot_optional_child(span, csetOff, floor)
  in if ot_condition_set_eval(b, cset, coords, axisCount)
    then ot_optional_child(span, substOff, floor)
    else find_active(n - 1, b, span, count, coords, axisCount, iadd(i, 1)) end

implement ot_feature_variations_active_subst(b, vinfo, coords, axisCount) =
  find_active(airlock_nat(vinfo.count), b, vinfo.span, vinfo.count, coords, axisCount, 0)

fun subst_feature(
  b: !Buf, subst: OtChild, index: int, fallback: OtFeatureInfo
): OtFeatureInfo = case+ subst.kind of
  | ChildPresent() => let
      val alt = ot_feature_table_subst_find(b, subst.span, index)
    in case+ alt.kind of
      | ChildPresent() => ot_feature_info(b, alt.span)
      | _ => fallback end
  | _ => fallback

implement ot_feature_at_with_variations(b, info, featureIndex, coords, axisCount) = let
  val base = ot_feature_at(b, info, featureIndex)
in case+ info.variations.kind of
  | ChildPresent() => (case+ ot_feature_variations_parse(b, info.variations.span) of
    | ~FeatureVariationsAccepted(vinfo) => let
        val active = ot_feature_variations_active_subst(b, vinfo, coords, axisCount)
      in subst_feature(b, active, featureIndex, base) end
    | ~FeatureVariationsRejected(_) => base)
  | _ => base end
