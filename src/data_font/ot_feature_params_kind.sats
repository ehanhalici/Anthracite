staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
(* Registered FeatureParams layouts. Every other tag is ParamsKindOpaque: its
   parameter bytes are not interpreted, so valid fonts are never rejected. *)
datatype OtParamsKind = ParamsKindSize | ParamsKindStylistic | ParamsKindVariant | ParamsKindOpaque
fun ot_params_kind_of(tag: OtTag): OtParamsKind
