#include "data_font/font_text_internal.hats"
staload "data_font/private/font_text_dispatch.sats"
implement font_draw(f,r,x,y,p,n,color) = if font_text_active(f) then let
  val source=font_text_raw_source(p,n) val result=font_text_draw(f,r,source,n,x,y,color)
  val ()=buf_free(source)
in font_text_result_pixels(result) end else font_legacy_draw(f,r,x,y,p,n,color)
implement font_width(f,r,p,n) = if font_text_active(f) then let
  val source=font_text_raw_source(p,n) val result=font_text_width(f,source,n) val ()=buf_free(source)
in font_text_result_pixels(result) end else font_legacy_width(f,r,p,n)
extern fun text_active_export(f: !Font): int = "ext#anth_font_text_active"
implement text_active_export(f) = if font_text_active(f) then 1 else 0
