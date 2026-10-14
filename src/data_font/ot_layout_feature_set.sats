staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
(* Takes ownership of a packed stream of four-byte ASCII tags, sorts it once. *)
fun ot_feature_set_parse(source: Buf): OtFeatureSetRead
fun ot_feature_set_contains(set: !OtFeatureSet,tag: OtTag): bool
fun ot_feature_set_dispose(set: OtFeatureSet): void
