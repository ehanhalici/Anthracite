staload "data_font/glyph_run_types.sats"
fun glyph_storage_capacity(count: int): bool
fun glyph_storage_make{n:nat}(count: int(n)): GlyphStorage(n)
fun glyph_storage_count{n:nat}(s: !GlyphStorage(n)): int(n)
fun glyph_storage_core{n:nat}(s: !GlyphStorage(n),index: int): GlyphCore
fun glyph_storage_links{n:nat}(s: !GlyphStorage(n),index: int): GlyphLinks
fun glyph_storage_position{n:nat}(s: !GlyphStorage(n),index: int): GlyphPosition
fun glyph_storage_set_core{n:nat}(s: !GlyphStorage(n),index: int,value: GlyphCore): void
fun glyph_storage_set_links{n:nat}(s: !GlyphStorage(n),index: int,value: GlyphLinks): void
fun glyph_storage_set_position{n:nat}(s: !GlyphStorage(n),index: int,value: GlyphPosition): void
fun glyph_storage_copy{n,m:nat}(source: !GlyphStorage(n),target: !GlyphStorage(m),count: int): void
fun glyph_storage_dispose{n:nat}(s: GlyphStorage(n)): void
fun glyph_core_empty(): GlyphCore
fun glyph_links_empty(): GlyphLinks
fun glyph_position_empty(): GlyphPosition
