#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/sfnt.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_feature_variations_types.sats"
staload "data_font/ot_feature_variations.sats"

fun axis_coord(coords: !Buf, axis: int, count: int): int =
  if ilt(axis, count) then let
    val at_0 = imul(axis, 2)
    val at_8 = iadd(8, imul(axis, 2))
  in if ige(buf_len(coords), iadd(at_8, 2)) andalso ieq(buf_len(coords), iadd(8, imul(count, 2)))
    then sfnt_signed16(coords, at_8)
    else if ige(buf_len(coords), iadd(at_0, 2)) then sfnt_signed16(coords, at_0)
    else 0 end
  else 0

implement ot_condition_eval(b, span, coords, axisCount) =
  if ilt(span.length, 8) then false else let
    val fmt = ot_u16(b, span, 0)
    val axis = ot_u16(b, span, 2)
    val minVal = sfnt_signed16(b, iadd(span.offset, 4))
    val maxVal = sfnt_signed16(b, iadd(span.offset, 6))
    val c = axis_coord(coords, axis, axisCount)
  in ieq(fmt, 1) andalso ile(minVal, maxVal) andalso ige(c, minVal) andalso ile(c, maxVal) end

fun all_conditions {n:nat} .<n>. (
  n: int(n), b: !Buf, span: OtSpan, coords: !Buf, axisCount: int, i: int
): bool =
  if n = 0 then true else let
    val off = ot_u32(b, span, iadd(2, imul(i, 4)))
    val child = ot_optional_child(span, off, iadd(2, imul(iadd(n, i), 4)))
  in case+ child.kind of
    | ChildPresent() => if ot_condition_eval(b, child.span, coords, axisCount)
        then all_conditions(n - 1, b, span, coords, axisCount, iadd(i, 1)) else false
    | _ => false end

implement ot_condition_set_eval(b, child, coords, axisCount) = case+ child.kind of
  | ChildMissing() => true
  | ChildInvalid() => false
  | ChildPresent() => let
      val span = child.span
    in if ilt(span.length, 2) then false else let
      val count = ot_u16(b, span, 0)
    in if ilt(span.length, iadd(2, imul(count, 4))) then false
      else all_conditions(airlock_nat(count), b, span, coords, axisCount, 0) end end
