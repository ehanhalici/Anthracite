#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "core_render/gl.sats"
staload "font/resources/font_gl_airlock.sats"
extern fun frame_capacity_failed(): void = "mac#anth_die_void"
(* Validate RGBA capacity before handing the owned bytes to the GL driver. *)
implement font_gl_read_pixels(b,w,h) =
  if ilt(w,1) orelse ilt(h,1) orelse igt(h,idiv(idiv(buf_cap(b),4),w)) then frame_capacity_failed()
  else font_gl_read_raw(20,isub(460,h),w,h,GL_RGBA,GL_UNSIGNED_BYTE,buf_ptr(b))
