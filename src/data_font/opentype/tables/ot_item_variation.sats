staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/definition/gdef_types.sats"
staload "data_font/opentype/tables/ot_item_variation_types.sats"

fun ot_item_var_store_parse(
  b: !Buf, span: OtSpan
): OtItemVarStoreRead

fun ot_item_var_region_scalar(
  b: !Buf, regions: OtVariationRegionList, regionIndex: int, coords: !Buf, axisCount: int
): int

fun ot_item_var_store_delta(
  b: !Buf, store: OtItemVarStoreInfo, outerIndex: int, innerIndex: int, coords: !Buf, axisCount: int
): int

fun ot_item_var_data_delta(
  b: !Buf, s: OtSpan, regions: OtVariationRegionList, inner: int, coords: !Buf, axisCount: int
): int

fun gdef_var_store_parse(
  b: !Buf, h: GdefHeaderInfo
): OtItemVarStoreRead

fun gdef_var_store_delta(
  b: !Buf, h: GdefHeaderInfo, outerIndex: int, innerIndex: int, coords: !Buf, axisCount: int
): int
