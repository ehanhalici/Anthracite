staload "data_text/unicode_property.sats"
staload "data_font/glyph_run_types.sats"
(* Source-derived hints are prepared before GSUB; normalization must already
   have preserved original byte spans. Hints survive cmap collisions/multiple
   output and never override real GDEF. Default-ignorable controls remain in the
   logical run for joining/context; rendering hides them only after shaping. *)
fun glyph_unicode_prepare(category: !PropertyMap(6),ignorables: !PropertyMap(8),run: GlyphRun(0)): GlyphRun(0)
