staload "mem.sats"
staload "data_font/resources/font.sats"
staload "data_font/text/font_text_types.sats"
staload "core_render/render.sats"
fun font_text_result_pixels(result: FontTextResult): int
fun font_text_raw_source(p: ptr,length: int): Buf
fun font_text_slice_source(b: !Buf,start: int,length: int): Buf
fun font_text_draw_baseline(f: !Font,r: !Rend,b: !Buf,length: int,x: double,baseline: double,color: uint): FontTextResult
fun font_text_scaled_buffer(f: !Font,r: !Rend,x: int,y: int,b: !Buf,n: int,color: uint,num: int,den: int): int
fun font_legacy_draw(f: !Font,r: !Rend,x: int,y: int,p: ptr,n: int,color: uint): int
fun font_legacy_width(f: !Font,r: !Rend,p: ptr,n: int): int
fun font_legacy_draw_scaled(f: !Font,r: !Rend,x: int,y: int,p: ptr,n: int,color: uint,num: int,den: int): int
fun font_legacy_draw_scaled_buf(f: !Font,r: !Rend,x: int,y: int,b: !Buf,n: int,color: uint,num: int,den: int): int
fun font_legacy_draw_buf(f: !Font,r: !Rend,x: int,y: int,b: !Buf,n: int,color: uint): int
fun font_legacy_draw_at(f: !Font,r: !Rend,x: int,y: int,b: !Buf,start: int,n: int,color: uint): int
fun font_legacy_width_buf(f: !Font,r: !Rend,b: !Buf,n: int): int
