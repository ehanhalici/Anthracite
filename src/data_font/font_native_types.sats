staload "data_font/font_glyph_id.sats"
staload "data_font/font_run.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/opentype_types.sats"
staload "data_font/native_shape_types.sats"
staload "data_text/script_types.sats"
staload "data_text/normalization_types.sats"
typedef FontNativeToken = @{face=FontGlyphFace,font=int,generation=int}
datavtype FontNativeRun = FontNativeRun of (GlyphPositioned(1),FontNativeToken)
datavtype FontNativeRead = FontNativeShaped of FontNativeRun | FontNativeNoFace
  | FontNativeCacheError of OtError | FontNativeUnsupported of ScriptCode
  | FontNativePlanError of OtError | FontNativeTextError of NormalizationError
  | FontNativeRunError of NativeShapeError
