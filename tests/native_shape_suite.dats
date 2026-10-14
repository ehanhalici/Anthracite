#include "native_shape_test.hats"
fun modifier(data: !NativeShapeData,n: !NormalizationData): int = case+ property_load(c_argv(8),ModifierMarkProperty()) of
  | ~PropertyRejected(e) => 1 | ~PropertyLoaded(mcm) => let val errors=native_test_faces(data,n,mcm)
    val ()=property_dispose(mcm) in errors end
fun normalized(data: !NativeShapeData): int = case+ normalization_load(c_argv(5)) of
  | ~NormalizationRejected(e) => 1 | ~NormalizationLoaded(n) => let val errors=modifier(data,n)
    val ()=normalization_dispose(n) in errors end
implement native_test_suite() = case+ native_test_data() of | ~None_vt() => 1 | ~Some_vt(data) => let
  val errors=normalized(data) val ()=native_shape_data_dispose(data)
in errors end
