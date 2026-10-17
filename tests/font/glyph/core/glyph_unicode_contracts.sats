staload "mem.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
fun unicode_glyph_test_run(category: !PropertyMap(6),ignored: !PropertyMap(8),errors: &int >> int): GlyphRun(0)
fun unicode_glyph_test_metadata(b: !Buf): GlyphMetadata
fun unicode_glyph_test_properties(category: !PropertyMap(6),ignored: !PropertyMap(8)): int
fun unicode_glyph_test_substitution(category: !PropertyMap(6),ignored: !PropertyMap(8)): int
