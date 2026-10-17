#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
#include "core_render/render_layout.hats"

staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "core_render/gl.sats"
staload "core_render/render.sats"

#define RENDER_BATCH_MAX_VERTICES 4096
#define RENDER_CLIP_INITIAL_BYTES 256

datavtype Rend_ = REND of @{
  prog= uint
, blur_prog= uint
, blur_tex= uint
, vao= uint
, vbo= uint
, loc_view= int
, loc_mode= int
, loc_tex= int
, blur_loc_view= int
, blur_loc_tex= int
, blur_loc_pixel= int
, batch= Buf
, clips= Buf
, nvert= int
, mode= Shade
, tex= uint
, vw= int
, vh= int
, blur_w= int
, blur_h= int
}
(* skill.md 1. kural istisnasi: ATS2 soyut tip gerceklemesi (sats'taki absviewtype). Kanit disi cast veya ham C yoktur. *)
assume Rend = Rend_


(* Private implementation groups share this owner and its linear representation. *)
#include "core_render/private/render/u0.hats"
#include "core_render/private/render/rend_quad_pixels.hats"
#include "core_render/private/render/nested_clip.hats"
