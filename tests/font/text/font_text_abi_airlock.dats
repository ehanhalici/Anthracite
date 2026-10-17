#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/resources/font.sats"
staload "core_render/render.sats"
staload "font/text/font_text_abi_airlock.sats"
%{#
#include "data_font/legacy/arabic.cats"
%}
extern fun wrapped_width(f: !Font,r: !Rend,p: ptr,n: int): int = "mac#anth_font_width_buf"
extern fun wrapped_draw(f: !Font,r: !Rend,x: int,y: int,p: ptr,n: int,c: uint): int = "mac#anth_font_draw_buf"
implement native_text_wrapped_width(f,r,b,n) = wrapped_width(f,r,buf_ptr(b),n)
implement native_text_wrapped_draw(f,r,b,n) = wrapped_draw(f,r,20,270,buf_ptr(b),n,0xFFFFFFFFu)
implement native_text_raw_width(f,r,b,n) = font_width(f,r,buf_ptr(b),n)
