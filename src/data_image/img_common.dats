#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "mem.sats"
staload "data_image/img_common.sats"

implement put4(b, r, g, bl, a) = let
  val () = buf_push(b, r)
  val () = buf_push(b, g)
  val () = buf_push(b, bl)
in
  buf_push(b, a)
end
