staload "data_font/glyph_position_types.sats"
staload "data_font/font_span_types.sats"
staload "data_font/font.sats"
staload "data_font/font_text_types.sats"
staload "mem.sats"
datatype TextQuery = QueryCaret of int | QueryClick of int
typedef TextHit = @{distance=int,value=int}
fun font_hit_edge(query: TextQuery,source: int,x: int,best: TextHit): TextHit
fun font_position_hit(p: !GlyphPositioned(1),offset: int,query: TextQuery,best: TextHit): TextHit
fun font_span_hit(layout: !FontSpanLayout,query: TextQuery): int
fun font_text_hit(f: !Font,b: !Buf,n: int,query: TextQuery): FontTextResult
