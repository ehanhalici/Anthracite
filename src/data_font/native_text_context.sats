staload "data_font/native_text_assets_types.sats"
staload "data_font/native_text_analysis_types.sats"
staload "data_font/native_text_context_types.sats"
staload "data_text/arabic_join_types.sats"
(* Two linear passes cache the nearest non-transparent neighbour at each
   scalar boundary, without joining across Unicode paragraph boundaries. *)
fun native_text_context_make(assets: !NativeTextAssets,a: !NativeTextAnalysis): NativeContextRead
fun native_text_context_at(contexts: !NativeTextContexts,start: int,finish: int): ArabicContext
fun native_text_context_dispose(contexts: NativeTextContexts): void
