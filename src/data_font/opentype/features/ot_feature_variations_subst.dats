#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/features/ot_feature_variations_types.sats"
staload "data_font/opentype/features/ot_feature_variations.sats"

fun missing_child(): OtChild =
  @{kind=ChildMissing(), span= @{offset=0, length=0}}

fun find_subst {n:nat} .<n>. (
  n: int(n), b: !Buf, span: OtSpan, target: int, floor: int, i: int
): OtChild =
  if n = 0 then missing_child() else let
    val at = iadd(6, imul(i, 6))
    val fidx = ot_u16(b, span, at)
  in if ieq(fidx, target) then let
    val altOff = ot_u32(b, span, iadd(at, 2))
  in ot_optional_child(span, altOff, floor) end
  else find_subst(n - 1, b, span, target, floor, iadd(i, 1)) end

implement ot_feature_table_subst_find(b, substSpan, featureIndex) =
  if ilt(substSpan.length, 6) then missing_child()
  else if ine(ot_u16(b, substSpan, 0), 1) then missing_child()
  else let
    val count = ot_u16(b, substSpan, 4)
    val floor = iadd(6, imul(count, 6))
  in if ilt(substSpan.length, floor) then missing_child()
    else find_subst(airlock_nat(count), b, substSpan, featureIndex, floor, 0) end
