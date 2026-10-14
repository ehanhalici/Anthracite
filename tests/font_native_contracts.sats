staload "core_render/render.sats"
staload "data_font/font.sats"
staload "data_font/font_native_types.sats"
staload "data_font/native_text_assets_types.sats"
staload "data_font/native_text_analysis_types.sats"
staload "data_font/native_text_context_types.sats"
staload "data_font/native_text_items_types.sats"
fun native_font_suite(r: !Rend): int
fun native_font_cases(r: !Rend,assets: !NativeTextAssets,a: !NativeTextAnalysis,
  contexts: !NativeTextContexts,items: !NativeTextItems): int
fun native_span_cases(r: !Rend,assets: !NativeTextAssets): int
fun native_span_boundary_cases(r: !Rend,assets: !NativeTextAssets): int
fun native_text_service_cases(r: !Rend): int
fun native_text_cache_cases(f: !Font): int
fun native_text_note_cases(f: !Font,r: !Rend): int
fun native_span_partition_cases(r: !Rend,assets: !NativeTextAssets): int
fun native_span_missing_cases(r: !Rend,assets: !NativeTextAssets): int
fun native_workspace_startup_case(r: !Rend): int
fun native_doc_navigation_cases(): int
fun native_font_registry_cases(): int
