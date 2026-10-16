#include "data_font/text/font_text_internal.hats"
staload "data_font/text/private/font_text_dispatch.sats"
extern fun scale_failed(): int = "mac#anth_die_int"
fun ppem(px: int,num: int,den: int): int = let
  val product=g0int2int_int_llint(px)*g0int2int_int_llint(num)
  val value=product/g0int2int_int_llint(den)
in if value < 1LL orelse value > 96LL then scale_failed() else airlock_i32(value) end
implement font_text_scaled_buffer(f,r,x,y,b,n,color,num,den) = let
  val numerator=if igt(num,0) then num else 1 val denominator=if igt(den,0) then den else 1
  val old=font_get_px(f) val size=ppem(old,numerator,denominator)
  val baseline=n_i2d(y)+n_i2d(font_asc(f))*n_i2d(size)/n_i2d(old)
  val ()=font_set_px_val(f,size)
  val result=font_text_draw_baseline(f,r,b,n,n_i2d(x),baseline,color)
  val ()=font_set_px_val(f,old)
in font_text_result_pixels(result) end
implement font_draw_scaled(f,r,x,y,p,n,color,num,den) = if font_text_active(f) then let
  val source=font_text_raw_source(p,n)
  val result=font_text_scaled_buffer(f,r,x,y,source,n,color,num,den) val ()=buf_free(source)
in result end else font_legacy_draw_scaled(f,r,x,y,p,n,color,num,den)
