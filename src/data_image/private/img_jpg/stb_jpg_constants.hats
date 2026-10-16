#include "common.hats"
#include "foundation/units.hats"

(* JPEG Marker byte definitions *)
macdef JPG_MARK_PREFIX = 255
macdef JPG_MARK_SOF0 = 192   (* 0xC0: Baseline DCT *)
macdef JPG_MARK_SOF1 = 193   (* 0xC1: Extended sequential DCT *)
macdef JPG_MARK_SOF2 = 194   (* 0xC2: Progressive DCT *)
macdef JPG_MARK_DHT = 196    (* 0xC4: Define Huffman Table *)
macdef JPG_MARK_RST0 = 208   (* 0xD0: Restart marker 0 *)
macdef JPG_MARK_RST7 = 215   (* 0xD7: Restart marker 7 *)
macdef JPG_MARK_SOI = 216    (* 0xD8: Start of Image *)
macdef JPG_MARK_EOI = 217    (* 0xD9: End of Image *)
macdef JPG_MARK_SOS = 218    (* 0xDA: Start of Scan *)
macdef JPG_MARK_DQT = 219    (* 0xDB: Define Quantization Table *)
macdef JPG_MARK_DNL = 220    (* 0xDC: Define Number of Lines *)
macdef JPG_MARK_DRI = 221    (* 0xDD: Define Restart Interval *)
macdef JPG_MARK_APP0 = 224   (* 0xE0: JFIF APP0 *)
macdef JPG_MARK_APP14 = 238  (* 0xEE: Adobe APP14 *)
macdef JPG_MARK_COM = 254    (* 0xFE: Comment *)
macdef JPG_MARK_NONE = 255

(* Structural and sizing limits *)
macdef JPG_FAST_BITS = 9
macdef JPG_FAST_BITS_SIZE = 512
macdef JPG_FAST_BITS_MASK = 511
macdef JPG_HUFF_SYMBOLS = 256
macdef JPG_HUFF_MAX_SIZES = 17
macdef JPG_DCT_BLOCK_SIZE = 64
macdef JPG_BLOCK_SIDE_PIXELS = 8
macdef JPG_MAX_COMPONENTS = 4
macdef JPG_MAX_TABLES = 4
macdef JPG_MAX_DIM_PIXELS = 8192
macdef JPG_MAX_TOTAL_PIXELS = 1048576
macdef JPG_COLOR_CHANNELS = 4
macdef JPG_MAX_SAMPLE_FACTOR = 4
macdef JPG_MAX_SUCCESSIVE_BITS = 13
macdef JPG_ADOBE_UNKNOWN = ~1
macdef JPG_ADOBE_CMYK_OR_RGB = 0
macdef JPG_ADOBE_YCCK = 2
macdef JPG_JFIF_TAG_BYTES = 5
macdef JPG_ADOBE_PAYLOAD_BYTES = 12
macdef JPG_ADOBE_TRANSFORM_OFFSET = 11

(* Bitwise integer helper functions *)
fun iand(a: int, b: int): int = anth_iand(a, b)

fun ior(a: int, b: int): int =
  g0uint2int_uint_int(g0uint_lor(g0int2uint_int_uint(a), g0int2uint_int_uint(b)))

fun ixor(a: int, b: int): int =
  g0uint2int_uint_int(g0uint_lxor(g0int2uint_int_uint(a), g0int2uint_int_uint(b)))

fun ishl(a: int, n: int): int =
  if ilt(n, 0) orelse ige(n, 32) then 0
  else g0uint2int_uint_int(g0uint_lsl(g0int2uint_int_uint(a), airlock_below(n, 32)))

fun ishr(a: int, n: int): int =
  if ilt(n, 0) orelse ige(n, 32) then 0
  else g0uint2int_uint_int(g0uint_lsr(g0int2uint_int_uint(a), airlock_below(n, 32)))

fun ashr(a: int, n: int): int =
  if ilt(n, 0) then a
  else if ige(n, 31) then (if ilt(a, 0) then ~1 else 0)
  else g0int_asr(a, airlock_below(n, 32))

fun clamp255(x: int): int =
  if ilt(x, 0) then 0 else if igt(x, 255) then 255 else x

fun bmask(n: int): int =
  if ieq(n, 0) then 0 else if ieq(n, 1) then 1 else if ieq(n, 2) then 3
  else if ieq(n, 3) then 7 else if ieq(n, 4) then 15 else if ieq(n, 5) then 31
  else if ieq(n, 6) then 63 else if ieq(n, 7) then 127 else if ieq(n, 8) then 255
  else if ieq(n, 9) then 511 else if ieq(n, 10) then 1023 else if ieq(n, 11) then 2047
  else if ieq(n, 12) then 4095 else if ieq(n, 13) then 8191 else if ieq(n, 14) then 16383
  else if ieq(n, 15) then 32767 else if ieq(n, 16) then 65535 else 0

fun jbias(n: int): int =
  if ieq(n, 0) then 0 else if ieq(n, 1) then ~1 else if ieq(n, 2) then ~3
  else if ieq(n, 3) then ~7 else if ieq(n, 4) then ~15 else if ieq(n, 5) then ~31
  else if ieq(n, 6) then ~63 else if ieq(n, 7) then ~127 else if ieq(n, 8) then ~255
  else if ieq(n, 9) then ~511 else if ieq(n, 10) then ~1023 else if ieq(n, 11) then ~2047
  else if ieq(n, 12) then ~4095 else if ieq(n, 13) then ~8191 else if ieq(n, 14) then ~16383
  else if ieq(n, 15) then ~32767 else 0

fun be16_at(b: !Buf, p: int): int =
  iadd(ishl(buf_get(b, p), 8), buf_get(b, iadd(p, 1)))
