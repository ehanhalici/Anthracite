staload "data_text/unicode/unicode_property.sats"
staload "data_text/arabic/joining/arabic_join_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
(* Logical scalar order, before GSUB. External context retains joining across
   font/itemization boundaries without owning or modifying neighbouring runs.
   This assigns four basic Arabic form masks, not Syriac joining-group rules,
   ligature substitution, mark positioning, or completed Arabic shaping. *)
fun glyph_arabic_prepare(map: !PropertyMap(3),plan: !ArabicMaskPlan,context: ArabicContext,
  run: GlyphRun(0)): GlyphRun(1)
