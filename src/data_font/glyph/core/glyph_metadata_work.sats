staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/definition/gdef_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
fun glyph_property_rows_make{n:nat}(count: int(n)): GlyphPropertyRows(n,0)
fun glyph_property_rows_append{n,i:nat | i < n}(rows: GlyphPropertyRows(n,i),property: GlyphProperty): GlyphPropertyRows(n,i+1)
fun glyph_property_rows_get{n:nat}(rows: !GlyphPropertyRows(n,n),index: int): GlyphProperty
fun glyph_property_rows_dispose{n,i:nat}(rows: GlyphPropertyRows(n,i)): void
fun glyph_property_rows_read(b: !Buf,classes: GdefClassMetadata,glyphs: int): [n:nat] GlyphPropertyRows(n,n)
fun glyph_metadata_empty_classes(): GdefClassMetadata
fun glyph_metadata_build(b: !Buf,classes: GdefClassMetadata,marks: GdefMarkSets,font: int,glyphs: int): GlyphMetadata
