staload "mem.sats"
staload "data_font/sfnt.sats"
staload "data_font/native_shape_types.sats"
staload "data_font/ot_shape_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_text/normalization_types.sats"
staload "data_text/unicode_property.sats"
fun native_test_data(): Option_vt(NativeShapeData)
fun native_test_request(profile: OtShapeProfile): OtShapeRequest
fun native_test_masks(): OtShapeMasks
fun native_test_example(face: !SfntFace,cache: !NativeShapeCache,plan: !NativeShapePlan,data: !NativeShapeData,
  normalization: !NormalizationData,mcm: !PropertyMap(9),source: string,words: string): int
fun native_test_faces(data: !NativeShapeData,normalization: !NormalizationData,mcm: !PropertyMap(9)): int
fun native_test_suite(): int
fun native_test_script_cases(): int
