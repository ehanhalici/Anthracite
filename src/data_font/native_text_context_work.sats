staload "data_font/native_text_context_types.sats"
staload "data_text/arabic_join_types.sats"
staload "data_text/utf8.sats"
staload "data_text/bidi_document.sats"
staload "data_text/unicode_property.sats"
fun native_context_before(map: !PropertyMap(3),text: !ScalarText,bidi: !BidiDocument,contexts: !NativeTextContexts): void
fun native_context_after(map: !PropertyMap(3),text: !ScalarText,bidi: !BidiDocument,contexts: !NativeTextContexts): void
fun native_context_set_before(contexts: !NativeTextContexts,index: int,value: ArabicBoundary): void
fun native_context_set_after(contexts: !NativeTextContexts,index: int,value: ArabicBoundary): void
fun native_context_next(map: !PropertyMap(3),cp: int,current: ArabicBoundary): ArabicBoundary
