staload "mem.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/native/shape/native_shape_types.sats"
staload "data_font/native/text/native_text_assets_types.sats"
staload "data_font/native/text/native_text_analysis_types.sats"
staload "data_font/native/text/native_text_items_types.sats"
staload "data_font/native/text/native_text_context_types.sats"
staload "data_font/native/text/native_text_shape_types.sats"
fun native_item_shape_planned(b: !Buf,info: SfntInfo,cache: !NativeShapeCache,assets: !NativeTextAssets,
  analysis: !NativeTextAnalysis,contexts: !NativeTextContexts,item: NativeTextItem,
  plan: !NativeShapePlan,scale: NativeShapeScale): NativeItemShapeRead
