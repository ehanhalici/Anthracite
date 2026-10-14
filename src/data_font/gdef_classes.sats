staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gdef_types.sats"
fun gdef_classes_parse(b: !Buf,header: GdefHeaderInfo,glyphs: int): GdefClassRead
fun gdef_glyph_kind(b: !Buf,metadata: GdefClassMetadata,glyph: int): GdefGlyphKind
fun gdef_mark_attachment(b: !Buf,metadata: GdefClassMetadata,glyph: int): int
fun gdef_glyph_kind_of(code: int): GdefGlyphKind
