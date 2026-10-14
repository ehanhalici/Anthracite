staload "mem.sats"
staload "data_font/sfnt.sats"
staload "data_font/ot_shape_types.sats"
staload "data_font/native_shape_types.sats"
staload "data_text/utf8.sats"
staload "data_text/arabic_join_types.sats"
staload "data_text/normalization_types.sats"
staload "data_text/unicode_property.sats"
(* Parse once per immutable face. The owning Font invalidates the cache before
   replacing its exact source bytes; caches/schedules never own duplicate faces. *)
fun native_shape_cache_parse(b: !Buf,info: SfntInfo,font: int): NativeShapeCacheRead
fun native_shape_cache_dispose(cache: NativeShapeCache): void
fun native_shape_plan_parse(b: !Buf,cache: !NativeShapeCache,request: OtShapeRequest,masks: OtShapeMasks): NativeShapePlanRead
fun native_shape_plan_dispose(plan: NativeShapePlan): void
fun native_shape_text_parse(b: !Buf,info: SfntInfo,plan: !NativeShapePlan,normalization: !NormalizationData,
  mcm: !PropertyMap(9),source: !ScalarText): NativeShapeTextRead
fun native_shape_text_dispose(text: NativeShapeText): void
fun native_shape_text_parse_range(b: !Buf,info: SfntInfo,plan: !NativeShapePlan,normalization: !NormalizationData,
  mcm: !PropertyMap(9),source: !ScalarText,start: int,finish: int): NativeShapeTextRead
(* Input is a prepared, itemized, original-source-mapped render view.
   This facade does not invent paragraph direction, choose fonts or wrap lines.
   External Arabic context preserves joining across item/font boundaries. *)
fun native_shape_run(b: !Buf,info: SfntInfo,cache: !NativeShapeCache,plan: !NativeShapePlan,data: !NativeShapeData,
  text: !NativeShapeText,context: ArabicContext,scale: NativeShapeScale): NativeShapeRead
fun native_shape_data_dispose(data: NativeShapeData): void
