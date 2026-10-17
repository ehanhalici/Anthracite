staload "data_text/script/script_types.sats"
staload "data_text/normalization/normalization_types.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/native/shape/native_shape_types.sats"
datavtype NativeItemShapeRead = NativeItemShaped of GlyphPositioned(1)
  | NativeItemUnsupported of ScriptCode | NativeItemPlanError of OtError
  | NativeItemTextError of NormalizationError | NativeItemRunError of NativeShapeError
