staload "data_font/atlas/font_glyph_id.sats"
staload "data_font/text/run/font_run.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/native/shape/native_shape_types.sats"
staload "data_text/script/script_types.sats"
staload "data_text/normalization/normalization_types.sats"
typedef FontNativeToken = @{face=FontGlyphFace,font=int,generation=int}
datavtype FontNativeRun = FontNativeRun of (GlyphPositioned(1),FontNativeToken)
datavtype FontNativeRead = FontNativeShaped of FontNativeRun | FontNativeNoFace
  | FontNativeCacheError of OtError | FontNativeUnsupported of ScriptCode
  | FontNativePlanError of OtError | FontNativeTextError of NormalizationError
  | FontNativeRunError of NativeShapeError
