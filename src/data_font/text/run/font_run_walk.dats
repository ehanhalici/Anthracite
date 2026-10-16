#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"
staload "data_font/atlas/font_glyph_id.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/text/run/font_run.sats"
staload "data_font/text/run/private/font_run_work.sats"
fun raster(f: !Font,r: !Rend,face: FontGlyphFace,view: GlyphView,scale: GlyphScale,origin: FontRunPen,
  x: double,y: double,color: uint): FontRunRasterResult =
  if view.core.ignorable then @{status=FontRunReady(),drawn=0}
  else font_run_raster(f,r,face,view.core.glyph,scale,origin,view.position,x,y,color)
fun walk{n:nat} .<n>. (left: int(n),f: !Font,r: !Rend,p: !GlyphPositioned(1),binding: FontRunBinding,
  d: GlyphPositionDirection,scale: GlyphScale,x: double,y: double,color: uint,node: int,pen: FontRunPen,extent: FontRunExtent): FontRunExtent =
  if left = 0 then extent else let val v=glyph_position_query(p,node)
    val step=raster(f,r,binding.face,v,scale,font_run_origin(d,pen,v.position),x,y,color)
    val next: FontRunExtent= @{status=step.status,xAdvance=extent.xAdvance,yAdvance=extent.yAdvance,drawn=iadd(extent.drawn,step.drawn)}
  in case+ step.status of | FontRunReady() => walk(left-1,f,r,p,binding,d,scale,x,y,color,v.links.next,font_run_next(d,pen,v.position),next)
    | FontRunFace() => next | FontRunScale() => next | FontRunOverflow() => next | FontRunRaster() => next | FontRunGraph() => next end
implement font_run_walk(f,r,p,binding,x,y,c,extent) = let val meta=glyph_position_meta(p) and d=glyph_position_direction(p)
in walk(airlock_nat(meta.live),f,r,p,binding,d,glyph_position_scale(p),x,y,c,meta.head,font_run_initial(d,extent),extent) end
