staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_window_types.sats"
typedef GlyphWindowRows = @{status=GlyphWindowStatus,count=int,input=int}
fun glyph_window_status_valid(status: GlyphWindowStatus): bool
fun glyph_window_span_valid(span: GlyphWindowSpan,limits: OtContextLimits,capacity: int): bool
fun glyph_window_reverse(glyphs: !Buf,nodes: !Buf,count: int): void
fun glyph_window_write{n:nat}(s: !GlyphStorage(n),node: int,glyphs: !Buf,nodes: !Buf,index: int): void
fun glyph_window_back{n:nat}(b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  o: GlyphWindowSelection,node: int,maximum: int,glyphs: !Buf,nodes: !Buf,remaining: &int >> _): GlyphWindowRows
fun glyph_window_forward{n:nat}(b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  o: GlyphWindowSelection,node: int,maximum: int,inputMaximum: int,start: int,glyphs: !Buf,nodes: !Buf,remaining: &int >> _): GlyphWindowRows
fun glyph_window_check{n:nat}(b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  o: GlyphWindowSelection,node: int): GlyphWindowStatus
