staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_cursive_types.sats"
fun gpos_cursive_parse(b: !Buf,span: OtSpan,glyphs: int): GposCursiveRead
fun gpos_cursive_query(b: !Buf,table: !GposCursive,glyph: int): GposCursiveView
fun gpos_cursive_pair(b: !Buf,table: !GposCursive,first: int,second: int): GposCursivePair
fun gpos_cursive_dispose(table: GposCursive): void
fun gpos_cursive_glyphs(table: !GposCursive): int
