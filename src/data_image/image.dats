#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef IMG_OPEN_BUFFER_INITIAL_BYTES = 4
macdef IMG_DECODE_TYPED_BUFFER_INITIAL_BYTES = 4
macdef IMG_LOAD_IMPL_RAW_INITIAL_BYTES = 64


staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "os/diag.sats"
staload "core_render/render.sats"
staload "data_image/image.sats"
staload "data_image/img_common.sats"
staload "data_image/img_png.sats"
staload "data_image/img_bmp.sats"
staload "data_image/img_jpg.sats"

macdef IMAGE_RGBA_CHANNELS = 4
macdef IMAGE_MAX_DIMENSION_PIXELS = 2048
macdef IMAGE_MAX_FILE_BYTES = 33554432
macdef IMAGE_FORMAT_UNKNOWN = 0
macdef IMAGE_FORMAT_PNG = 1
macdef IMAGE_FORMAT_BMP = 2
macdef IMAGE_FORMAT_JPEG = 3
macdef PNG_SIGNATURE_FIRST = 137
macdef PNG_SIGNATURE_P = 80
macdef PNG_SIGNATURE_N = 78
macdef PNG_SIGNATURE_G = 71
macdef BMP_SIGNATURE_B = 66
macdef BMP_SIGNATURE_M = 77
macdef JPEG_MARKER_PREFIX = 255
macdef JPEG_MARKER_START = 216

datavtype Image_ = IMG of @{w= int, h= int, px= Buf, ok= Toggle}
assume Image = Image_

implement img_open() = IMG(@{w= 0, h= 0, px= buf_make(IMG_OPEN_BUFFER_INITIAL_BYTES), ok= Off})

implement img_free(im) = let
  val+~IMG(s) = im
in
  buf_free(s.px)
end

implement image_width(im) = case+ im of | @IMG(s) => let val v = s.w in fold@(im); v end
implement image_height(im) = case+ im of | @IMG(s) => let val v = s.h in fold@(im); v end

implement img_upload(im, r) =
  case+ im of
  | @IMG(s) => let
      val t = if is_off(s.ok) then u_zero() else rend_tex_buf(r, s.w, s.h, s.px)
    in
      fold@(im); t
    end

fun img_store(im: !Image, px: Buf, w: int, h: int): void =
  case+ im of
  | @IMG(s) => let
      val old = s.px
      val () = s.px := px
      val () = s.w := w
      val () = s.h := h
      val () = s.ok := On
      val () = fold@(im)
      val () = buf_free(old)
    in
    end

fun img_detect_type(src: !Buf): int =
  if buf_len(src) < WORD32_BYTES then IMAGE_FORMAT_UNKNOWN
  else if ieq(buf_get(src, 0), PNG_SIGNATURE_FIRST) andalso ieq(buf_get(src, 1), PNG_SIGNATURE_P)
    andalso ieq(buf_get(src, 2), PNG_SIGNATURE_N) andalso ieq(buf_get(src, 3), PNG_SIGNATURE_G) then IMAGE_FORMAT_PNG
  else if ieq(buf_get(src, 0), BMP_SIGNATURE_B) andalso ieq(buf_get(src, 1), BMP_SIGNATURE_M) then IMAGE_FORMAT_BMP
  else if ieq(buf_get(src, 0), JPEG_MARKER_PREFIX) andalso ieq(buf_get(src, 1), JPEG_MARKER_START) then IMAGE_FORMAT_JPEG
  else IMAGE_FORMAT_UNKNOWN

fun img_decode_typed(ty: int, src: !Buf, w: &int >> _, h: &int >> _): Buf =
  if ieq(ty, IMAGE_FORMAT_PNG) then decode_png(src, w, h)
  else if ieq(ty, IMAGE_FORMAT_BMP) then decode_bmp(src, w, h)
  else if ieq(ty, IMAGE_FORMAT_JPEG) then decode_jpg(src, w, h)
  else buf_make(IMG_DECODE_TYPED_BUFFER_INITIAL_BYTES)

fun img_downscale_if_needed(im: !Image, w: int, h: int): void =
  if w > IMAGE_MAX_DIMENSION_PIXELS orelse h > IMAGE_MAX_DIMENSION_PIXELS then let
    val rw = if w >= h then IMAGE_MAX_DIMENSION_PIXELS else imax(1, idiv(imul(w, IMAGE_MAX_DIMENSION_PIXELS), h))
    val rh = if w >= h then imax(1, idiv(imul(h, IMAGE_MAX_DIMENSION_PIXELS), w)) else IMAGE_MAX_DIMENSION_PIXELS
  in
    seen_int(img_resize(im, rw, rh))
  end else ()

fun img_read_file(path: string, dst: &Buf >> _): bool = let
  val sz = fs_size(path)
in
  if sz <= 0 orelse sz > IMAGE_MAX_FILE_BYTES then false
  else let
    val fd = fs_open_read(path)
  in
    if fd < 0 then false
    else let
      val () = buf_set_len(dst, 0)
      val () = buf_ensure(dst, iadd(sz, 1))
      val n = fs_read_buf(fd, dst, sz)
      val () = fs_close(fd)
      val () = buf_set_len(dst, if igt(n, 0) then n else 0)
    in
      igt(n, 0)
    end
  end
end

fun img_apply_decoded(im: !Image, px: Buf, w: int, h: int, path: string, f: string, l: int): int =
  if w > 0 andalso h > 0 then let
    val sz = imul(imul(w, h), 4)
    val () = if buf_len(px) < sz then buf_set_len(px, sz) else ()
    val () = img_store(im, px, w, h)
    val () = img_downscale_if_needed(im, w, h)
    val () = log_info_at(f, l, "IMAGE", "loaded successfully", path)
  in
    1
  end else let
    val () = buf_free(px)
    val () = log_error_at(f, l, "IMAGE", "decode failed", path)
  in
    0
  end

fun img_load_impl(im: !Image, path: string, f: string, l: int): int = let
  var raw = buf_make(IMG_LOAD_IMPL_RAW_INITIAL_BYTES)
  val ok = img_read_file(path, raw)
in
  if not(ok) then let
    val () = buf_free(raw)
    val () = log_error_at(f, l, "IMAGE", "file open/read failed", path)
  in
    0
  end else let
    val ty = img_detect_type(raw)
    var w: int = 0
    var h: int = 0
    val px = img_decode_typed(ty, raw, w, h)
    val () = buf_free(raw)
  in
    img_apply_decoded(im, px, w, h, path, f, l)
  end
end

implement img_load_at(im, path, file, line) = img_load_impl(im, path, file, line)
implement img_load(im, path) = img_load_impl(im, path, $extval(string, "__FILE__"), $extval(int, "__LINE__"))

fun resize_px_copy(src: !Buf, dst: &Buf >> _, spos: int): void = let
  val () = buf_push(dst, buf_get(src, spos))
  val () = buf_push(dst, buf_get(src, iadd(spos, 1)))
  val () = buf_push(dst, buf_get(src, iadd(spos, 2)))
  val () = buf_push(dst, buf_get(src, iadd(spos, 3)))
in
end

extern fun resize_row_fuel_exhausted(src: !Buf, dst: &Buf >> _, sw: int, sh: int, tw: int, th: int, ty: int, tx: int): void = "mac#anth_die_void"

fun resize_row_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), src: !Buf, dst: &Buf >> _, sw: int, sh: int, tw: int, th: int, ty: int, tx: int
): void =
  if recfuel > 0 then (
    if ilt(tx, tw) then let
      val sx = idiv(imul(tx, sw), tw)
      val sy = idiv(imul(ty, sh), th)
      val spos = imul(iadd(imul(sy, sw), sx), 4)
      val () = resize_px_copy(src, dst, spos)
    in
      resize_row_with_fuel(recfuel - 1, src, dst, sw, sh, tw, th, ty, iadd(tx, 1))
    end else ()
  ) else resize_row_fuel_exhausted(src, dst, sw, sh, tw, th, ty, tx)

extern fun resize_rows_fuel_exhausted(src: !Buf, dst: &Buf >> _, sw: int, sh: int, tw: int, th: int, ty: int): void = "mac#anth_die_void"

fun resize_rows_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), src: !Buf, dst: &Buf >> _, sw: int, sh: int, tw: int, th: int, ty: int
): void =
  if recfuel > 0 then (
    if ilt(ty, th) then let
      val () = resize_row_with_fuel(airlock_nat(MAX_REC_FUEL), src, dst, sw, sh, tw, th, ty, 0)
    in
      resize_rows_with_fuel(recfuel - 1, src, dst, sw, sh, tw, th, iadd(ty, 1))
    end else ()
  ) else resize_rows_fuel_exhausted(src, dst, sw, sh, tw, th, ty)

fun img_resize_apply(im: !Image, in_w: int, in_h: int, tw: int, th: int): int = let
  val sz = imul(imul(tw, th), 4)
  var new_px = buf_make(iadd(sz, 16))
in
  case+ im of
  | @IMG(s) => let
      val () = resize_rows_with_fuel(airlock_nat(MAX_REC_FUEL), s.px, new_px, in_w, in_h, tw, th, 0)
      val old_px = s.px
      val () = s.px := new_px
      val () = s.w := tw
      val () = s.h := th
      val () = fold@(im)
      val () = buf_free(old_px)
    in
      1
    end
end

implement img_resize(im, tw, th) =
  case+ im of
  | @IMG(s) => let
      val in_w = s.w
      val in_h = s.h
      val invalid = ile(tw, 0) orelse ile(th, 0) orelse ile(in_w, 0) orelse ile(in_h, 0)
      val () = fold@(im)
    in
      if invalid then 0 else img_resize_apply(im, in_w, in_h, tw, th)
    end

fun write_buf(path: string, b: !Buf): void = let
  val n = buf_len(b)
in
  seen_int(fs_write_buf(path, b, n))
end

fun pix(im: !Image, i: int): int =
  case+ im of
  | @IMG(s) => let
      val v = buf_get(s.px, i)
    in
      fold@(im); v
    end

fun selftest_write_png_bmp(): void = let
  val pb = make_png()
  val () = write_buf("/tmp/anth-t.png", pb)
  val () = buf_free(pb)
  val bb = make_bmp()
  val () = write_buf("/tmp/anth-t.bmp", bb)
  val () = buf_free(bb)
in
end

fun selftest_png_ok(im: !Image): int = let
  val pn = img_load(im, "/tmp/anth-t.png")
  val pr = pix(im, 0)
  val pg = pix(im, 1)
  val pb2 = pix(im, 2)
  val bad = img_load(im, "/tmp/anth_nonexistent_test.png")
  val up = "/home/emrehan/notes/obsidian_notlar/din/eklenti/vird/raditu billahi rabba.png"
  val texture_is_valid = (if fs_exists(up) = 1 then img_load(im, up) else 1): int
in
  (if ieq(pn, 1) andalso ieq(bad, 0) andalso ieq(texture_is_valid, 1) andalso ieq(pr, 10) andalso ieq(pg, 20) andalso ieq(pb2, 30) then 1 else 0)
end

fun selftest_bmp_ok(im: !Image): int = let
  val bn = img_load(im, "/tmp/anth-t.bmp")
  val br = pix(im, 0)
  val bg = pix(im, 1)
  val bb2 = pix(im, 2)
in
  (if ieq(bn, 1) andalso ieq(image_width(im), 2) andalso ieq(image_height(im), 1) andalso ieq(br, 10) andalso ieq(bg, 20) andalso ieq(bb2, 30) then 1 else 0)
end

fun selftest_jpg_ok(im: !Image, pok: int, bok: int): int = let
  val jb = make_jpg()
  val () = write_buf("/tmp/anth-t.jpg", jb)
  val () = buf_free(jb)
  val jn = img_load(im, "/tmp/anth-t.jpg")
  val jr = pix(im, 0)
  val jg = pix(im, 1)
  val jbl = pix(im, 2)
  val jok = (if ieq(jn, 1) andalso ieq(image_width(im), 8) andalso ieq(image_height(im), 8) andalso ile(iabs(isub(jr, 40)), 30) andalso ile(iabs(isub(jg, 90)), 30) andalso ile(iabs(isub(jbl, 140)), 30) then 1 else 0) : int
  val rok = img_resize(im, 4, 4)
  val r_w = image_width(im)
  val r_h = image_height(im)
  val resize_ok = (if ieq(rok, 1) andalso ieq(r_w, 4) andalso ieq(r_h, 4) then 1 else 0) : int
  val () = println! ("png=", pok, " bmp=", bok, " jpg=", jok, " resize=", resize_ok, " r=", jr, " g=", jg, " b=", jbl)
in
  if ieq(jok, 1) andalso ieq(resize_ok, 1) then 1 else 0
end

implement img_selftest() = let
  val () = selftest_write_png_bmp()
  val im = img_open()
  val pok = selftest_png_ok(im)
  val bok = selftest_bmp_ok(im)
  val jok = selftest_jpg_ok(im, pok, bok)
  val () = img_free(im)
in
  (if ieq(pok, 1) andalso ieq(bok, 1) andalso ieq(jok, 1) then 1 else 0)
end
