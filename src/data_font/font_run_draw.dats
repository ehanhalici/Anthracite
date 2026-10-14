#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "data_font/font.sats"
staload "core_render/render.sats"
staload "data_font/font_glyph_id.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/font_run.sats"
staload "data_font/private/font_run_work.sats"
fun measured(f: !Font,r: !Rend,p: !GlyphPositioned(1),b: FontRunBinding,x: double,y: double,c: uint): FontRunExtent = let
  val extent=font_run_measure(p)
in case+ extent.status of | FontRunReady() => font_run_walk(f,r,p,b,x,y,c,extent)
  | FontRunFace() => extent | FontRunScale() => extent | FontRunOverflow() => extent | FontRunRaster() => extent | FontRunGraph() => extent end
implement font_draw_positioned(f,r,p,binding,x,y,c) = let val status=font_run_binding_check(f,p,binding) in
  case+ status of | FontRunReady() => measured(f,r,p,binding,x,y,c)
    | FontRunFace() => @{status=status,xAdvance=0,yAdvance=0,drawn=0}
    | FontRunScale() => @{status=status,xAdvance=0,yAdvance=0,drawn=0}
    | FontRunOverflow() => @{status=status,xAdvance=0,yAdvance=0,drawn=0}
    | FontRunRaster() => @{status=status,xAdvance=0,yAdvance=0,drawn=0}
    | FontRunGraph() => @{status=status,xAdvance=0,yAdvance=0,drawn=0} end
