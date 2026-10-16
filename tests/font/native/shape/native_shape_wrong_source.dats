#include "data_font/native/shape/native_shape_internal.hats"
fun illegal(b: !Buf,info: SfntInfo,cache: !NativeShapeCache,plan: !NativeShapePlan,data: !NativeShapeData,
  source: !ScalarText,context: ArabicContext,scale: NativeShapeScale): NativeShapeRead =
  native_shape_run(b,info,cache,plan,data,source,context,scale)
