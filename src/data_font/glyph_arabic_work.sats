staload "data_text/unicode_property.sats"
staload "data_text/arabic_join_types.sats"
staload "data_font/glyph_run_types.sats"
fun glyph_arabic_form{n:nat}(storage: !GlyphStorage(n),node: int,form: ArabicForm,plan: !ArabicMaskPlan): void
fun glyph_arabic_promote{n:nat}(storage: !GlyphStorage(n),node: int,form: ArabicForm,plan: !ArabicMaskPlan): void
fun glyph_arabic_walk{n:nat}(map: !PropertyMap(3),plan: !ArabicMaskPlan,context: ArabicContext,
  storage: !GlyphStorage(n),meta: GlyphRunMeta): void
