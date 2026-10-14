#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "flag.sats"
staload "os/fs.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"
staload "data_font/font_glyph_id.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/font_run.sats"
staload "data_font/private/font_run_work.sats"
fun quad(f: !Font,r: !Rend,g: gmet,scale: GlyphScale,origin: FontRunPen,p: GlyphPosition,x: double,y: double,c: uint): int =
  if ieq(g.bw,0) orelse ieq(g.bh,0) then 0 else let
    val box=font_run_quad(origin,p,scale,g,x,y)
    val aw=n_i2d(font_atlas_w(f)) and ah=n_i2d(font_atlas_h(f))
    val ()=rend_quad_pixels(r,font_tex(f),ShadeAlpha(),box.x,box.y,box.w,box.h,
      n_i2d(g.x0)/aw,n_i2d(g.y0)/ah,n_i2d(iadd(g.x0,g.bw))/aw,n_i2d(iadd(g.y0,g.bh))/ah,c)
  in 1 end
implement font_run_raster(f,r,face,glyph,scale,origin,p,x,y,c) = let
  var g: gmet= @{ax=0,bx=0,top=0,bw=0,bh=0,x0=0,y0=0,ok=Off()}
  val status=font_glyph_id(f,r,face,glyph,g)
in case+ status of | GlyphRasterUnavailable() => @{status=FontRunRaster(),drawn=0}
  | GlyphRasterDomain() => @{status=FontRunFace(),drawn=0}
  | GlyphRasterReady() => if is_off(g.ok) then @{status=FontRunRaster(),drawn=0}
    else @{status=FontRunReady(),drawn=quad(f,r,g,scale,origin,p,x,y,c)} end
