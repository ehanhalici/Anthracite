staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_single_types.sats"
fun gpos_single_parse(b: !Buf,span: OtSpan,glyphs: int): GposSingleRead
fun gpos_single_query(b: !Buf,table: !GposSingle,glyph: int): GposSingleView
fun gpos_single_glyphs(table: !GposSingle): int
fun gpos_single_dispose(table: GposSingle): void
