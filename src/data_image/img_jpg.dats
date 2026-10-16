#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef JPG_FINISH_BUFFER_INITIAL_BYTES = 4
macdef DECODE_JPG_META_INITIAL_BYTES = 256
macdef DECODE_JPG_BUFFER_INITIAL_BYTES = 1024
macdef DECODE_JPG_BUFFER_ALTERNATE_INITIAL_BYTES = 6400
macdef DECODE_JPG_COEF_INITIAL_BYTES = 256
macdef DECODE_JPG_SAMP_INITIAL_BYTES = 4096


staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "core_render/render.sats"
staload "data_image/img_common.sats"
staload "data_image/img_jpg.sats"


(* Private implementation groups share this owner and its linear representation. *)
#include "data_image/private/img_jpg/pow2.hats"
#include "data_image/private/img_jpg/jblk_ac.hats"
#include "data_image/private/img_jpg/sof_one.hats"
#include "data_image/private/img_jpg/paint_row.hats"
#include "data_image/private/img_jpg/jpg_byte_1.hats"
