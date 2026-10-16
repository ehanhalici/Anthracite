staload "mem.sats"
staload "data_font/resources/font.sats"
staload "data_font/text/span/font_span.sats"
staload "data_font/text/span/font_span_types.sats"
staload "data_font/native/text/native_text_assets_types.sats"
staload "data_font/native/text/native_text_analysis_types.sats"
staload "data_font/native/text/native_text_context_types.sats"
staload "data_font/native/text/native_text_items_types.sats"
staload "data_font/native/ownership/font_native_types.sats"
fun font_span_fill(f: !Font,assets: !NativeTextAssets,a: !NativeTextAnalysis,contexts: !NativeTextContexts,
  layout: !FontSpanLayout,options: FontSpanOptions): Option_vt(FontSpanFailure)
fun font_span_order(assets: !NativeTextAssets,layout: !FontSpanLayout): void
fun font_span_set_part(layout: !FontSpanLayout,index: int,row: FontSpanPart): void
fun font_span_part(layout: !FontSpanLayout,index: int): FontSpanPart
fun font_span_total(layout: !FontSpanLayout): Option_vt(int)
fun font_span_shape(f: !Font,assets: !NativeTextAssets,a: !NativeTextAnalysis,c: !NativeTextContexts,
  item: NativeTextItem,options: FontSpanOptions): FontNativeRead
fun font_span_space_shape(f: !Font,assets: !NativeTextAssets,options: FontSpanOptions): FontNativeRead
fun font_span_tab_place(layout: !FontSpanLayout,index: int,pen: llint): Option_vt(FontSpanFailure)
fun font_span_line_end_place(layout: !FontSpanLayout,index: int): void
