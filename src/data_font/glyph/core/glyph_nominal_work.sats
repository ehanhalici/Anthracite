staload "mem.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_db.sats"
fun glyph_nominal_fill{n:nat}(face: !SfntFace,db: !UnicodeDb,text: !ScalarText,
  storage: !GlyphStorage(n),mask: uint,count: int): void
fun glyph_nominal_fill_bytes{n:nat}(b: !Buf,info: SfntInfo,db: !UnicodeDb,text: !ScalarText,
  storage: !GlyphStorage(n),mask: uint,count: int): void
fun glyph_nominal_meta(meta: GlyphRunMeta,count: int): GlyphRunMeta
fun glyph_nominal_source_extent(text: !ScalarText): int
