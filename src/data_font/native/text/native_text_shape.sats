staload "mem.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/native/shape/native_shape_types.sats"
staload "data_font/opentype/shape/ot_shape_types.sats"
staload "data_font/native/text/native_text_assets_types.sats"
staload "data_font/native/text/native_text_analysis_types.sats"
staload "data_font/native/text/native_text_items_types.sats"
staload "data_font/native/text/native_text_context_types.sats"
staload "data_font/native/text/native_text_shape_types.sats"
(* The caller supplies a selected, unchanged face and its cache. This bridge
   borrows an analysis range, applies its script/direction and external Arabic
   context, then returns a frozen run with original source byte spans.
   Font selection, visual order, wrapping and GPU work remain separate. *)
fun native_text_item_shape(b: !Buf,info: SfntInfo,cache: !NativeShapeCache,assets: !NativeTextAssets,
  analysis: !NativeTextAnalysis,contexts: !NativeTextContexts,item: NativeTextItem,
  language: OtShapeLanguage,masks: OtShapeMasks,scale: NativeShapeScale): NativeItemShapeRead
