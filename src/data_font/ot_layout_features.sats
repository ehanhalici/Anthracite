staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
fun ot_feature_info(b: !Buf,span: OtSpan): OtFeatureInfo
fun ot_features_validate(b: !Buf,info: OtLayoutInfo): Option_vt(OtError)
fun ot_feature_at(b: !Buf,info: OtLayoutInfo,index: int): OtFeatureInfo
