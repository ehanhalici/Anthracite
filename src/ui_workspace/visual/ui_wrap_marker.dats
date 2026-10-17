#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "core_render/render.sats"
(* Editor decoration, not document text: it must not depend on a font's cmap. *)
extern fun wrap_marker(r: !Rend,x: int,y: int,color: uint): void = "ext#anth_ui_wrap_marker"
implement wrap_marker(r,x,y,color) = let
  val ()=rend_rect(r,iadd(x,8),iadd(y,4),1,6,color)
  val ()=rend_rect(r,iadd(x,3),iadd(y,9),6,1,color)
  val ()=rend_rect(r,iadd(x,1),iadd(y,9),1,1,color)
  val ()=rend_rect(r,iadd(x,2),iadd(y,8),1,3,color)
in rend_rect(r,iadd(x,3),iadd(y,7),1,5,color) end
