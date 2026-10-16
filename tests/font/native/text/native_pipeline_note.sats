staload "data_font/native/text/native_text_assets_types.sats"
staload "data_font/native/text/native_text_analysis_types.sats"
staload "data_font/native/text/native_text_context_types.sats"
staload "data_font/native/text/native_text_items_types.sats"
staload "data_font/native/shape/native_shape_types.sats"
staload "data_font/sfnt/sfnt.sats"
typedef PipelineNoteStats = @{items=int,glyphs=int,missing=int,spans=int,marks=int,advances=int,failures=int}
fun pipeline_note_walk(assets: !NativeTextAssets,a: !NativeTextAnalysis,contexts: !NativeTextContexts,
  items: !NativeTextItems,latin: !SfntFace,lc: !NativeShapeCache,arabic: !SfntFace,ac: !NativeShapeCache): PipelineNoteStats
