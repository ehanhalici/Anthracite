staload "data_font/native/text/native_text_analysis_types.sats"
staload "data_font/native/text/native_text_items_types.sats"
fun native_text_item_finish(a: !NativeTextAnalysis,start: int): int
fun native_text_item_read(a: !NativeTextAnalysis,start: int,finish: int): NativeTextItem
fun native_text_items_measure(a: !NativeTextAnalysis): int
fun native_text_items_fill(a: !NativeTextAnalysis,items: !NativeTextItems): void
fun native_text_items_set(items: !NativeTextItems,index: int,item: NativeTextItem): void
