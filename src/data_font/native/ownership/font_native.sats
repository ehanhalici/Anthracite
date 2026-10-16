staload "data_font/resources/font.sats"
staload "data_font/atlas/font_glyph_id.sats"
staload "data_font/text/run/font_run.sats"
staload "data_font/native/ownership/font_native_types.sats"
staload "data_font/native/text/native_text_assets_types.sats"
staload "data_font/native/text/native_text_analysis_types.sats"
staload "data_font/native/text/native_text_context_types.sats"
staload "data_font/native/text/native_text_items_types.sats"
staload "data_font/opentype/shape/ot_shape_types.sats"
staload "data_font/native/shape/native_shape_types.sats"
staload "core_render/render.sats"
(* Registry IDs must be nonnegative and unique across live faces. They cannot
   change while this face generation is cached. Font owns the exact bytes and
   lazy cache. No font/file clone is created during shaping. *)
fun font_shape_native_item(f: !Font,assets: !NativeTextAssets,a: !NativeTextAnalysis,
  contexts: !NativeTextContexts,item: NativeTextItem,face: FontGlyphFace,font: int,
  language: OtShapeLanguage,masks: OtShapeMasks,scale: NativeShapeScale): FontNativeRead
fun font_native_run_check(f: !Font,run: !FontNativeRun): FontRunStatus
fun font_draw_native_run(f: !Font,r: !Rend,run: !FontNativeRun,x: double,baseline: double,color: uint): FontRunExtent
fun font_native_run_dispose(run: FontNativeRun): void
(* Conservative whole-item candidate check. Does not split an EGC or borrow
   Font's bytes beyond the call; shaping success is a separate condition. *)
fun font_native_item_covered(f: !Font,assets: !NativeTextAssets,a: !NativeTextAnalysis,
  item: NativeTextItem,face: FontGlyphFace): bool
