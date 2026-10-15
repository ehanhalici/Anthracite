#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/sfnt.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/gdef_types.sats"
staload "data_font/ot_item_variation_types.sats"
staload "data_font/ot_item_variation.sats"

fun validate_subtables {n:nat} .<n>. (
  n: int(n), b: !Buf, span: OtSpan, floor: int, i: int
): bool =
  if n = 0 then true else let
    val off = ot_u32(b, span, iadd(8, imul(i, 4)))
    val child = ot_optional_child(span, off, floor)
  in case+ child.kind of
    | ChildPresent() => if ige(child.span.length, 6)
        then validate_subtables(n - 1, b, span, floor, iadd(i, 1)) else false
    | _ => false end

fun check_region_bounds(
  span: OtSpan, rspan: OtSpan, axisCount: int, regionCount: int, count: int, floor: int, b: !Buf
): OtItemVarStoreRead = let
  val needed = iadd(4, imul(regionCount, imul(axisCount, 6)))
in if ilt(rspan.length, needed) then ItemVarStoreRejected(ot_error(OtBounds(), span))
  else if not(validate_subtables(airlock_nat(count), b, span, floor, 0))
    then ItemVarStoreRejected(ot_error(OtBounds(), span))
  else let
    val rlist: OtVariationRegionList = @{span=rspan, axisCount=axisCount, regionCount=regionCount}
    val info: OtItemVarStoreInfo = @{span=span, regions=rlist, dataCount=count}
  in ItemVarStoreAccepted(info) end end

fun parse_store_regions(b: !Buf, span: OtSpan, rlistChild: OtChild, count: int, floor: int): OtItemVarStoreRead =
  case+ rlistChild.kind of
  | ChildPresent() => let
      val rspan = rlistChild.span
    in if ilt(rspan.length, 4) then ItemVarStoreRejected(ot_error(OtBounds(), span)) else let
      val axisCount = ot_u16(b, rspan, 0)
      val regionCount = ot_u16(b, rspan, 2)
    in check_region_bounds(span, rspan, axisCount, regionCount, count, floor, b) end end
  | _ => ItemVarStoreRejected(ot_error(OtBounds(), span))

implement ot_item_var_store_parse(b, span) =
  if not(ot_span_valid(b, span)) orelse ilt(span.length, 8)
    then ItemVarStoreRejected(ot_error(OtBounds(), span))
  else if ine(ot_u16(b, span, 0), 1)
    then ItemVarStoreRejected(ot_error(OtFormat(), span))
  else let
    val rlistOff = ot_u32(b, span, 2)
    val count = ot_u16(b, span, 6)
    val floor = iadd(8, imul(count, 4))
    val rlist = ot_optional_child(span, rlistOff, floor)
  in parse_store_regions(b, span, rlist, count, floor) end

implement ot_item_var_store_delta(b, store, outerIndex, innerIndex, coords, axisCount) =
  if ilt(outerIndex, 0) orelse ige(outerIndex, store.dataCount) then 0 else let
    val off = ot_u32(b, store.span, iadd(8, imul(outerIndex, 4)))
    val floor = iadd(8, imul(store.dataCount, 4))
    val child = ot_optional_child(store.span, off, floor)
  in case+ child.kind of
    | ChildPresent() => ot_item_var_data_delta(b, child.span, store.regions, innerIndex, coords, axisCount)
    | _ => 0 end

implement gdef_var_store_parse(b, h) = case+ h.variations.kind of
  | ChildPresent() => ot_item_var_store_parse(b, h.variations.span)
  | _ => ItemVarStoreRejected(ot_error(OtBounds(), h.span))

implement gdef_var_store_delta(b, h, outerIndex, innerIndex, coords, axisCount) =
  case+ gdef_var_store_parse(b, h) of
  | ~ItemVarStoreAccepted(store) => ot_item_var_store_delta(b, store, outerIndex, innerIndex, coords, axisCount)
  | ~ItemVarStoreRejected(_) => 0
