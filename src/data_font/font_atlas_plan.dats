#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"
staload "data_font/private/font_storage.sats"
staload "data_font/private/font_atlas.sats"
implement font_atlas_plan(f,bw,bh) = let
  val px=f_get_pen_x(f) and py=f_get_pen_y(f) and row=f_get_row_h(f)
  val wrap=ige(iadd(iadd(px,bw),1),font_atlas_w(f))
  val x: int=if wrap then 1 else px
  val y: int=if wrap then iadd(iadd(py,row),1) else py
  val height: int=if wrap then 0 else row
  val reset=ige(iadd(iadd(y,bh),1),font_atlas_h(f))
in @{x=if reset then 1 else x,y=if reset then 1 else y,
  row=imax(bh,if reset then 0 else height),reset=reset} end
