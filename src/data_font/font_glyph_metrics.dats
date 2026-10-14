#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "flag.sats"
staload "data_font/font.sats"
staload "data_font/private/font_cache.sats"
implement fill_g(g,ax,bx,top,bw,bh,x0,y0) = let
  val ()=g.ax := ax and ()=g.bx := bx and ()=g.top := top
  val ()=g.bw := bw and ()=g.bh := bh and ()=g.x0 := x0 and ()=g.y0 := y0
  val ()=g.ok := On()
in () end
