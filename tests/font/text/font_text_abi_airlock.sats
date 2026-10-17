staload "mem.sats"
staload "data_font/resources/font.sats"
staload "core_render/render.sats"
fun native_text_wrapped_width(f: !Font,r: !Rend,b: !Buf,n: int): int
fun native_text_wrapped_draw(f: !Font,r: !Rend,b: !Buf,n: int): int
fun native_text_raw_width(f: !Font,r: !Rend,b: !Buf,n: int): int
