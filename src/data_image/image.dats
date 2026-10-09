#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "core_render/render.sats"
staload "data_image/image.sats"
staload "data_image/img_common.sats"
staload "data_image/img_png.sats"
staload "data_image/img_bmp.sats"
staload "data_image/img_jpg.sats"

extern fun pow2_exh(n: int): int = "mac#anth_die_int"

fun pow2_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), n: int): int =
  if recfuel > 0 then (
  if n <= 0 then 1 else imul(pow2_m(recfuel - 1, n - 1), 2)
  ) else pow2_exh(n)

fun pow2(n: int): int = pow2_m(airlock_nat(MAX_REC_FUEL), n)

fun ishl(a: int, n: int): int = imul(a, pow2(n))
fun ishr(a: int, n: int): int = if n <= 0 then a else idiv(a, ishl(1, n))
fun iand(a: int, n: int): int = anth_iand(a, n)

datavtype Image_ = IMG of @{w= int, h= int, px= Buf, ok= Toggle}
(* skill.md 1. kural istisnasi: ATS2 soyut tip gerceklemesi (sats'taki absviewtype). Kanit disi cast veya ham C yoktur. *)
assume Image = Image_

implement img_open() = IMG(@{w= 0, h= 0, px= buf_make(4), ok= Off})

implement img_free(im) = let
  val+~IMG(s) = im
in
  buf_free(s.px)
end

implement img_w(im) = case+ im of | @IMG(s) => let val v = s.w in fold@(im); v end
implement img_h(im) = case+ im of | @IMG(s) => let val v = s.h in fold@(im); v end

implement img_upload(im, r) =
  case+ im of
  | @IMG(s) => let
      val t = if is_off(s.ok) then u_zero() else rend_tex_buf(r, s.w, s.h, s.px)
    in
      fold@(im); t
    end

macdef MIN_IMAGE_FILE_SIZE = 8
macdef MAX_IMAGE_FILE_SIZE = 8000000

macdef PNG_HEADER_MIN_LEN = 8
macdef PNG_MAGIC_0 = 137
macdef PNG_MAGIC_1 = 80

macdef JPG_HEADER_MIN_LEN = 4
macdef JPG_MAGIC_0 = 255
macdef JPG_MAGIC_1 = 216

macdef BMP_HEADER_MIN_LEN = 26
macdef BMP_MAGIC_0 = 66
macdef BMP_MAGIC_1 = 77

fun read_file(path: string): Buf = let
  val sz = fs_size(path)
in
  if sz < MIN_IMAGE_FILE_SIZE orelse sz > MAX_IMAGE_FILE_SIZE then buf_make(1)
  else let
    val fd = fs_open_read(path)
    val b = buf_make(iadd(sz, 1))
  in
    if fd < 0 then b
    else let
      val n = fs_read_buf(fd, b, sz)
      val () = fs_close(fd)
      val () = buf_set_len(b, if igt(n, 0) then n else 0)
    in
      b
    end
  end
end

fun decode_any(src: !Buf, w: &int >> _, h: &int >> _): Buf =
  if ige(buf_len(src), PNG_HEADER_MIN_LEN) andalso ieq(buf_get(src, 0), PNG_MAGIC_0) andalso ieq(buf_get(src, 1), PNG_MAGIC_1) then decode_png(src, w, h)
  else if ige(buf_len(src), JPG_HEADER_MIN_LEN) andalso ieq(buf_get(src, 0), JPG_MAGIC_0) andalso ieq(buf_get(src, 1), JPG_MAGIC_1) then decode_jpg(src, w, h)
  else if ige(buf_len(src), BMP_HEADER_MIN_LEN) andalso ieq(buf_get(src, 0), BMP_MAGIC_0) andalso ieq(buf_get(src, 1), BMP_MAGIC_1) then decode_bmp(src, w, h)
  else let
    val () = w := 0
    val () = h := 0
  in
    buf_make(4)
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

implement img_load(im, path) = let
  val src = read_file(path)
  var w: int = 0
  var h: int = 0
  val px = decode_any(src, w, h)
  val () = buf_free(src)
in
  if ile(w, 0) then let
    val () = buf_free(px)
  in
    0
  end else let
    val () = img_store(im, px, w, h)
  in
    1
  end
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
in
  (if ieq(pn, 1) andalso ieq(img_w(im), 1) andalso ieq(img_h(im), 1) andalso ieq(pr, 10) andalso ieq(pg, 20) andalso ieq(pb2, 30) then 1 else 0)
end

fun selftest_bmp_ok(im: !Image): int = let
  val bn = img_load(im, "/tmp/anth-t.bmp")
  val br = pix(im, 0)
  val bg = pix(im, 1)
  val bb2 = pix(im, 2)
in
  (if ieq(bn, 1) andalso ieq(img_w(im), 2) andalso ieq(img_h(im), 1) andalso ieq(br, 10) andalso ieq(bg, 20) andalso ieq(bb2, 30) then 1 else 0)
end

fun selftest_jpg_ok(im: !Image, pok: int, bok: int): int = let
  val jb = make_jpg()
  val () = write_buf("/tmp/anth-t.jpg", jb)
  val () = buf_free(jb)
  val jn = img_load(im, "/tmp/anth-t.jpg")
  val jr = pix(im, 0)
  val jg = pix(im, 1)
  val jbl = pix(im, 2)
  val jok = (if ieq(jn, 1) andalso ieq(img_w(im), 8) andalso ieq(img_h(im), 8) andalso ile(iabs(isub(jr, 40)), 30) andalso ile(iabs(isub(jg, 90)), 30) andalso ile(iabs(isub(jbl, 140)), 30) then 1 else 0) : int
  val () = println! ("png=", pok, " bmp=", bok, " jpg=", jok, " r=", jr, " g=", jg, " b=", jbl)
in
  jok
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

