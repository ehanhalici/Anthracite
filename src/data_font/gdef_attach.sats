staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gdef_types.sats"
staload "data_font/gdef_attach_types.sats"
fun gdef_attach_parse(b: !Buf,header: GdefHeaderInfo,glyphs: int): GdefAttachRead
fun gdef_attach_count(attach: !GdefAttachList): int
fun gdef_attach_point(b: !Buf,attach: !GdefAttachList,glyph: int): GdefAttachPoint
fun gdef_attach_dispose(attach: GdefAttachList): void
fun gdef_carets_parse(b: !Buf,header: GdefHeaderInfo,glyphs: int): GdefLigCaretsRead
fun gdef_carets_count(carets: !GdefLigCarets): int
fun gdef_carets_ligature(b: !Buf,carets: !GdefLigCarets,glyph: int): GdefLigGlyph
fun gdef_caret_value(b: !Buf,carets: !GdefLigCarets,lig: GdefLigGlyph,index: int): GdefCaretValue
fun gdef_carets_dispose(carets: GdefLigCarets): void
