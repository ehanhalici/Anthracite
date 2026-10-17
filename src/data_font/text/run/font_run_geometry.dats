#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "os/fs.sats"
staload "data_font/resources/font.sats"
staload "data_font/atlas/font_glyph_id.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/text/run/font_run.sats"
staload "data_font/text/run/private/font_run_work.sats"
implement font_run_initial(d,e) = case+ d of | PositionLTR() => @{x=0,y=0} | PositionRTL() => @{x=e.xAdvance,y=e.yAdvance}
implement font_run_origin(d,pen,p) = case+ d of | PositionLTR() => pen
  | PositionRTL() => @{x=pen.x-p.xAdvance,y=pen.y-p.yAdvance}
implement font_run_next(d,pen,p) = case+ d of | PositionLTR() => @{x=pen.x+p.xAdvance,y=pen.y+p.yAdvance}
  | PositionRTL() => @{x=pen.x-p.xAdvance,y=pen.y-p.yAdvance}
implement font_run_quad(origin,p,scale,g,x,baseline) = let
  val stretch=n_i2d(scale.xPpem)/n_i2d(scale.yPpem)
in @{x=x+n_i2d(origin.x)/64.0+n_i2d(p.xOffset)/64.0+n_i2d(g.bx)*stretch,
  y=baseline-n_i2d(origin.y)/64.0-n_i2d(p.yOffset)/64.0-n_i2d(g.top),
  w=n_i2d(g.bw)*stretch,h=n_i2d(g.bh)} end
