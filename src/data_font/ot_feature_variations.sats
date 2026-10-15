staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_feature_variations_types.sats"

fun ot_feature_variations_parse(
  b: !Buf, span: OtSpan
): OtFeatureVariationsRead

fun ot_feature_variations_validate(
  b: !Buf, info: OtLayoutInfo, remaining: &int >> _
): Option_vt(OtError)

fun ot_condition_eval(
  b: !Buf, span: OtSpan, coords: !Buf, axisCount: int
): bool

fun ot_condition_set_eval(
  b: !Buf, child: OtChild, coords: !Buf, axisCount: int
): bool

fun ot_feature_variations_active_subst(
  b: !Buf, vinfo: OtFeatureVariationsInfo, coords: !Buf, axisCount: int
): OtChild

fun ot_feature_table_subst_find(
  b: !Buf, substSpan: OtSpan, featureIndex: int
): OtChild

fun ot_feature_at_with_variations(
  b: !Buf, info: OtLayoutInfo, featureIndex: int, coords: !Buf, axisCount: int
): OtFeatureInfo
