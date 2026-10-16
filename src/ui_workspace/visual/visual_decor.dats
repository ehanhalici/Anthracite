#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "mem.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/syntax/ast.sats"
staload "data_font/resources/font.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "ui_workspace/visual/visual_paint.sats"
staload "ui_workspace/visual/visual_decor.sats"
implement visual_leaf_background(f,r,d,a,b,colx,oy,scroll,lh,ph,style,scratch) =
  if ine(anth_iand(style,STYLE_HIGH),0) then visual_draw_band(f,r,d,a,b,colx,oy,scroll,lh,ph,0,lh,col_highbg(),scratch) else ()
implement visual_leaf_rules(f,r,d,a,b,colx,oy,scroll,lh,ph,style,scratch) = let
  val ()=if ine(anth_iand(style,STYLE_LINK),0) then
    visual_draw_band(f,r,d,a,b,colx,oy,scroll,lh,ph,isub(lh,2),1,col_link(),scratch) else ()
  val ()=if ine(anth_iand(style,STYLE_STRIKE),0) then
    visual_draw_band(f,r,d,a,b,colx,oy,scroll,lh,ph,idiv(lh,2),1,col_muted(),scratch) else ()
in if ine(anth_iand(style,STYLE_ERROR),0) then
  visual_draw_band(f,r,d,a,b,colx,oy,scroll,lh,ph,isub(lh,2),2,col_danger(),scratch) else () end
