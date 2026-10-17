staload "mem.sats"
staload "data_font/native/text/native_text_assets_types.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/native/shape/native_shape_types.sats"
fun pipeline_bytes(text: string): Buf
fun pipeline_range_cases(assets: !NativeTextAssets): int
fun pipeline_context_cases(assets: !NativeTextAssets): int
fun pipeline_coverage_cases(assets: !NativeTextAssets): int
fun pipeline_shape_cases(assets: !NativeTextAssets,latin: !SfntFace,arabic: !SfntFace): int
fun pipeline_note_cases(assets: !NativeTextAssets,latin: !SfntFace,arabic: !SfntFace,path: string): int
fun pipeline_joined_case(assets: !NativeTextAssets,arabic: !SfntFace,cache: !NativeShapeCache): int
