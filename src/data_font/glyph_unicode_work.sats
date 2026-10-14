staload "data_font/gdef_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_text/unicode_property.sats"
fun glyph_unicode_kind_of(category: int,ignorable: bool): GdefGlyphKind
fun glyph_unicode_core(core: GlyphCore,kind: GdefGlyphKind,ignorable: bool): GlyphCore
fun glyph_unicode_walk{n:nat}(category: !PropertyMap(6),ignorables: !PropertyMap(8),s: !GlyphStorage(n),meta: GlyphRunMeta): void
