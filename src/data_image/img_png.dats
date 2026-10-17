#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef INFLATE_TAB_INITIAL_BYTES = 16384
macdef PNG_RESULT_BUFFER_INITIAL_BYTES = 4
macdef DECODE_PNG_IDAT_INITIAL_BYTES = 64
macdef DECODE_PNG_INF_INITIAL_BYTES = 64


staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "data_image/img_common.sats"
staload "data_image/img_png.sats"


(* Private implementation groups share this owner and its linear representation. *)
#include "data_image/private/img_png/pow2.hats"
#include "data_image/private/img_png/dbase0.hats"
#include "data_image/private/img_png/read_lens.hats"
#include "data_image/private/img_png/put_color.hats"
#include "data_image/private/img_png/push_png.hats"
