#include "data_font/font_text_internal.hats"
staload "data_font/private/font_text_dispatch.sats"
implement font_draw_buf(f,r,x,y,b,n,color) = if font_text_active(f) then
  font_text_result_pixels(font_text_draw(f,r,b,n,x,y,color)) else font_legacy_draw_buf(f,r,x,y,b,n,color)
implement font_width_buf(f,r,b,n) = if font_text_active(f) then
  font_text_result_pixels(font_text_width(f,b,n)) else font_legacy_width_buf(f,r,b,n)
implement font_draw_at(f,r,x,y,b,start,n,color) = if font_text_active(f) then let
  val source=font_text_slice_source(b,start,n)
  val result=font_text_draw(f,r,source,n,x,y,color) val ()=buf_free(source)
in font_text_result_pixels(result) end else font_legacy_draw_at(f,r,x,y,b,start,n,color)
implement font_draw_scaled_buf(f,r,x,y,b,n,color,num,den) = if font_text_active(f) then
  font_text_scaled_buffer(f,r,x,y,b,n,color,num,den) else font_legacy_draw_scaled_buf(f,r,x,y,b,n,color,num,den)
