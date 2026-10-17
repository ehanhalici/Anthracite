#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/features/ot_feature_variations_types.sats"
staload "data_font/opentype/features/ot_feature_variations.sats"

implement ot_feature_variations_parse(b, span) =
  if not(ot_span_valid(b, span)) orelse ilt(span.length, 8)
    then FeatureVariationsRejected(ot_error(OtBounds(), span))
  else if ine(ot_u16(b, span, 0), 1) orelse ine(ot_u16(b, span, 2), 0)
    then FeatureVariationsRejected(ot_error(OtFormat(), span))
  else let
    val count = ot_u32(b, span, 4)
  in if ilt(count, 0) orelse not(ot_rows_fit(span, 8, count, 8))
    then FeatureVariationsRejected(ot_error(OtBounds(), span))
    else FeatureVariationsAccepted(@{span=span, count=count}) end

fun validate_lookups {n:nat} .<n>. (
  n: int(n), b: !Buf, span: OtSpan, lookups: int, i: int
): bool =
  if n = 0 then true else let
    val idx = ot_u16(b, span, iadd(4, imul(i, 2)))
  in if ige(idx, lookups) then false
    else validate_lookups(n - 1, b, span, lookups, iadd(i, 1)) end

fun validate_alt_feature(b: !Buf, s: OtSpan, lookups: int): bool =
  if ilt(s.length, 4) then false else let
    val count = ot_u16(b, s, 2)
  in if ilt(s.length, iadd(4, imul(count, 2))) then false
    else validate_lookups(airlock_nat(count), b, s, lookups, 0) end

fun validate_subst_records {n:nat} .<n>. (
  n: int(n), b: !Buf, s: OtSpan, features: int, lookups: int, floor: int, i: int
): bool =
  if n = 0 then true else let
    val at = iadd(6, imul(i, 6))
    val fidx = ot_u16(b, s, at)
    val altOff = ot_u32(b, s, iadd(at, 2))
    val alt = ot_optional_child(s, altOff, floor)
  in if ige(fidx, features) then false
    else case+ alt.kind of
      | ChildPresent() => if validate_alt_feature(b, alt.span, lookups)
          then validate_subst_records(n - 1, b, s, features, lookups, floor, iadd(i, 1)) else false
      | _ => false end

fun validate_subst_table(b: !Buf, s: OtSpan, features: int, lookups: int): bool =
  if ilt(s.length, 6) then false
  else if ine(ot_u16(b, s, 0), 1) orelse ine(ot_u16(b, s, 2), 0) then false
  else let
    val count = ot_u16(b, s, 4)
    val floor = iadd(6, imul(count, 6))
  in if ilt(s.length, floor) then false
    else validate_subst_records(airlock_nat(count), b, s, features, lookups, floor, 0) end

fun validate_condition(b: !Buf, s: OtSpan): bool =
  if ilt(s.length, 8) then false else let
    val fmt = ot_u16(b, s, 0)
    val minVal = sfnt_signed16(b, iadd(s.offset, 4))
    val maxVal = sfnt_signed16(b, iadd(s.offset, 6))
  in ieq(fmt, 1) andalso ile(minVal, maxVal) end

fun validate_conditions {n:nat} .<n>. (
  n: int(n), b: !Buf, s: OtSpan, floor: int, i: int
): bool =
  if n = 0 then true else let
    val off = ot_u32(b, s, iadd(2, imul(i, 4)))
    val child = ot_optional_child(s, off, floor)
  in case+ child.kind of
    | ChildPresent() => if validate_condition(b, child.span)
        then validate_conditions(n - 1, b, s, floor, iadd(i, 1)) else false
    | _ => false end

fun validate_condition_set(b: !Buf, s: OtSpan): bool =
  if ilt(s.length, 2) then false else let
    val count = ot_u16(b, s, 0)
    val floor = iadd(2, imul(count, 4))
  in if ilt(s.length, floor) then false
    else validate_conditions(airlock_nat(count), b, s, floor, 0) end

fun cset_valid(b: !Buf, cset: OtChild): bool = case+ cset.kind of
  | ChildMissing() => true
  | ChildInvalid() => false
  | ChildPresent() => validate_condition_set(b, cset.span)

fun subst_valid(b: !Buf, subst: OtChild, features: int, lookups: int): bool = case+ subst.kind of
  | ChildPresent() => validate_subst_table(b, subst.span, features, lookups)
  | _ => false

fun validate_variation_records {n:nat} .<n>. (
  n: int(n), b: !Buf, s: OtSpan, count: int, info: OtLayoutInfo, i: int
): Option_vt(OtError) =
  if n = 0 then None_vt() else let
    val at = iadd(8, imul(i, 8))
    val floor = iadd(8, imul(count, 8))
    val csetOff = ot_u32(b, s, at)
    val substOff = ot_u32(b, s, iadd(at, 4))
    val cset = ot_optional_child(s, csetOff, floor)
    val subst = ot_optional_child(s, substOff, floor)
  in if not(cset_valid(b, cset)) orelse not(subst_valid(b, subst, info.features.count, info.lookupCount))
    then Some_vt(ot_error(OtBounds(), s))
    else validate_variation_records(n - 1, b, s, count, info, iadd(i, 1)) end

implement ot_feature_variations_validate(b, info, remaining) =
  case+ info.variations.kind of
  | ChildMissing() => None_vt()
  | ChildInvalid() => Some_vt(ot_error(OtBounds(), info.span))
  | ChildPresent() => let
      val span = info.variations.span
    in case+ ot_feature_variations_parse(b, span) of
      | ~FeatureVariationsRejected(e) => Some_vt(e)
      | ~FeatureVariationsAccepted(vinfo) =>
          validate_variation_records(airlock_nat(vinfo.count), b, span, vinfo.count, info, 0) end
