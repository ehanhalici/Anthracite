staload "mem.sats"
staload "data_font/resources/font.sats"
staload "data_font/resources/font_paint.sats"
staload "data_font/text/font_text_types.sats"
staload "core_render/render.sats"
fun font_text_paint(f: !Font,r: !Rend,b: !Buf,n: int,paint: TextPaint,x: int,y: int,c: uint): FontTextResult
