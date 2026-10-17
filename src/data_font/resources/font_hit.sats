staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/text/span/font_span_types.sats"
staload "data_font/resources/font.sats"
staload "data_font/text/font_text_types.sats"
staload "mem.sats"
typedef TextQuery = @{caret=bool,value=int}
macdef QueryCaret(byte) = @{caret=true,value=,(byte)}
macdef QueryClick(pixel) = @{caret=false,value=,(pixel)}
typedef TextHit = @{distance=int,value=int}
fun font_hit_edge(query: TextQuery,source: int,x: int,best: TextHit): TextHit
fun font_position_hit(p: !GlyphPositioned(1),offset: int,query: TextQuery,best: TextHit): TextHit
fun font_span_hit(layout: !FontSpanLayout,query: TextQuery): int
fun font_span_text_hit(layout: !FontSpanLayout,query: TextQuery,length: int): int
fun font_text_hit(f: !Font,b: !Buf,n: int,query: TextQuery): FontTextResult
