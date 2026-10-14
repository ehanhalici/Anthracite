staload "data_font/native_text_analysis_types.sats"
staload "data_font/native_text_items_types.sats"
staload "data_font/ot_shape_types.sats"
(* EGCs are indivisible. A cluster uses its leading scalar's resolved level;
   changes inside that cluster must not detach marks from their base. *)
fun native_text_items_make(a: !NativeTextAnalysis): NativeItemsRead
fun native_text_items_count(items: !NativeTextItems): int
fun native_text_items_at(items: !NativeTextItems,index: int): NativeTextItem
fun native_text_item_direction(item: NativeTextItem): OtShapeDirection
fun native_text_items_dispose(items: NativeTextItems): void
