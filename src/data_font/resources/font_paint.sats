staload "data_font/resources/font.sats"
staload "data_font/text/run/font_run.sats"
staload "data_font/native/ownership/font_native_types.sats"
staload "data_font/text/span/font_span_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "core_render/render.sats"
typedef TextRange = @{start=int,finish=int}
datatype TextPaint = PaintGlyphs of TextRange | PaintSelection of (TextRange,int)
fun font_position_paint(f: !Font,r: !Rend,p: !GlyphPositioned(1),token: FontNativeToken,
  range: TextRange,x: double,y: double,color: uint): FontRunStatus
fun font_position_select(r: !Rend,p: !GlyphPositioned(1),range: TextRange,x: double,y: double,height: int,color: uint): void
fun font_span_paint(f: !Font,r: !Rend,layout: !FontSpanLayout,paint: TextPaint,x: double,y: double,color: uint): FontRunStatus
