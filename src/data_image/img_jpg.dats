#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

(* JPEG algorithms translated from stb_image v2.29 by Sean Barrett and
   contributors. Original copyright and MIT/public-domain notices: vendor/stb. *)

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "core_render/render.sats"
staload "data_image/img_common.sats"
staload "data_image/img_jpg.sats"

#include "data_image/private/img_jpg/stb_jpg_constants.hats"
#include "data_image/private/img_jpg/stb_jpg_tables.hats"
#include "data_image/private/img_jpg/stb_jpg_idct.hats"
#include "data_image/private/img_jpg/stb_jpg_huffman.hats"
#include "data_image/private/img_jpg/stb_jpg_markers.hats"
#include "data_image/private/img_jpg/stb_jpg_scan.hats"
#include "data_image/private/img_jpg/stb_jpg_resample.hats"
#include "data_image/private/img_jpg/jpeg_color.hats"
#include "data_image/private/img_jpg/stb_jpg_decode.hats"
#include "data_image/private/img_jpg/jpg_byte_1.hats"

implement decode_jpg(src, wout, hout) =
  stbi_jpeg_decode_entry(src, wout, hout)
