staload "data_text/script_types.sats"
staload "data_text/normalization_types.sats"
staload "data_font/opentype_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/native_shape_types.sats"
datavtype NativeItemShapeRead = NativeItemShaped of GlyphPositioned(1)
  | NativeItemUnsupported of ScriptCode | NativeItemPlanError of OtError
  | NativeItemTextError of NormalizationError | NativeItemRunError of NativeShapeError
