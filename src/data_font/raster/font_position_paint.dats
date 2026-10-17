#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "data_font/resources/font.sats"
staload "data_font/text/run/font_run.sats"
staload "data_font/native/ownership/font_native_types.sats"
staload "data_font/resources/font_paint.sats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/text/run/private/font_run_work.sats"
staload "core_render/render.sats"
fun step(f: !Font,r: !Rend,p: !GlyphPositioned(1),token: FontNativeToken,v: GlyphView,range: TextRange,
  origin: FontRunPen,x: double,y: double,c: uint): FontRunStatus =
  if v.core.ignorable orelse ilt(v.core.sourceStart,range.start) orelse ige(v.core.sourceStart,range.finish) then FontRunReady()
  else let val result=font_run_raster(f,r,token.face,v.core.glyph,glyph_position_scale(p),origin,v.position,x,y,c)
  in result.status end
fun walk{n:nat} .<n>. (left: int(n),f: !Font,r: !Rend,p: !GlyphPositioned(1),token: FontNativeToken,
  range: TextRange,x: double,y: double,c: uint,node: int,pen: FontRunPen): FontRunStatus =
  if left = 0 then FontRunReady() else let val v=glyph_position_query(p,node) val direction=glyph_position_direction(p)
    val status=step(f,r,p,token,v,range,font_run_origin(direction,pen,v.position),x,y,c)
  in case+ status of | FontRunReady() => walk(left-1,f,r,p,token,range,x,y,c,v.links.next,font_run_next(direction,pen,v.position))
    | FontRunFace() => status | FontRunScale() => status | FontRunOverflow() => status
    | FontRunRaster() => status | FontRunGraph() => status end
implement font_position_paint(f,r,p,token,range,x,y,c) = let
  val meta=glyph_position_meta(p) val extent=font_run_measure(p)
in walk(airlock_nat(meta.live),f,r,p,token,range,x,y,c,meta.head,font_run_initial(glyph_position_direction(p),extent)) end
