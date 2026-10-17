staload "mem.sats"
staload "data_font/resources/font.sats"
staload "data_font/atlas/font_glyph_id.sats"
staload "data_font/native/ownership/font_native_types.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/native/shape/native_shape_types.sats"
staload "data_font/native/text/native_text_assets_types.sats"
staload "data_font/native/text/native_text_analysis_types.sats"
staload "data_font/native/text/native_text_context_types.sats"
staload "data_font/native/text/native_text_items_types.sats"
staload "data_font/opentype/shape/ot_shape_types.sats"
fun font_native_cache_release(slot: Option_vt(NativeShapeCache)): void
fun font_native_cache_reset(slot: &Option_vt(NativeShapeCache) >> _): void
fun font_native_generation_next(value: int): int
fun font_native_current(f: !Font,face: FontGlyphFace): FontNativeToken
fun font_native_slot_shape(slot: &Option_vt(NativeShapeCache) >> _,b: !Buf,info: SfntInfo,
  assets: !NativeTextAssets,a: !NativeTextAnalysis,contexts: !NativeTextContexts,item: NativeTextItem,
  token: FontNativeToken,language: OtShapeLanguage,masks: OtShapeMasks,scale: NativeShapeScale): FontNativeRead
fun font_native_primary_shape(slot: &Option_vt(NativeShapeCache) >> _,b: !Buf,info: SfntMetadata,
  assets: !NativeTextAssets,a: !NativeTextAnalysis,contexts: !NativeTextContexts,item: NativeTextItem,
  token: FontNativeToken,language: OtShapeLanguage,masks: OtShapeMasks,scale: NativeShapeScale): FontNativeRead
fun font_native_fallback_shape(slot: &Option_vt(NativeShapeCache) >> _,b: &Option_vt(Buf) >> _,info: SfntMetadata,
  assets: !NativeTextAssets,a: !NativeTextAnalysis,contexts: !NativeTextContexts,item: NativeTextItem,
  token: FontNativeToken,language: OtShapeLanguage,masks: OtShapeMasks,scale: NativeShapeScale): FontNativeRead
