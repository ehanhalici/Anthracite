#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "mem.sats"
staload "os/fs.sats"
staload "data_font/font_paint.sats"
staload "data_font/font_run.sats"
staload "data_font/glyph_position.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/private/font_run_work.sats"
staload "core_render/render.sats"
fun box(r: !Rend,v: GlyphView,range: TextRange,origin: FontRunPen,x: double,y: double,h: int,c: uint): void =
  if igt(v.core.sourceEnd,range.start) andalso ilt(v.core.sourceStart,range.finish) andalso igt(v.position.xAdvance,0) then
    rend_quad_pixels(r,u_zero(),ShadeSolid(),x+n_i2d(origin.x)/64.0,y,n_i2d(v.position.xAdvance)/64.0,n_i2d(h),0.0,0.0,0.0,0.0,c)
  else ()
fun walk{n:nat} .<n>. (left: int(n),r: !Rend,p: !GlyphPositioned(1),range: TextRange,x: double,y: double,h: int,c: uint,
  node: int,pen: FontRunPen): void = if left = 0 then () else let val v=glyph_position_query(p,node)
    val d=glyph_position_direction(p) val ()=box(r,v,range,font_run_origin(d,pen,v.position),x,y,h,c)
  in walk(left-1,r,p,range,x,y,h,c,v.links.next,font_run_next(d,pen,v.position)) end
implement font_position_select(r,p,range,x,y,h,c) = let val meta=glyph_position_meta(p) val extent=font_run_measure(p)
in walk(airlock_nat(meta.live),r,p,range,x,y,h,c,meta.head,font_run_initial(glyph_position_direction(p),extent)) end
