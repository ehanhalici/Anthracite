#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "os/fs.sats"
staload "core_render/render.sats"
staload "data_image/image.sats"
staload "data_image/img_common.sats"
staload "data_image/img_png.sats"
staload "data_image/img_bmp.sats"
staload "data_image/img_jpg.sats"

fun pow2(n: int): int = if n <= 0 then 1 else imul(pow2(n - 1), 2)
fun ishl(a: int, n: int): int = imul(a, pow2(n))
fun ishr(a: int, n: int): int = if n <= 0 then a else idiv(a, ishl(1, n))
fun iand(a: int, n: int): int = anth_iand(a, n)

datavtype Image_ = IMG of @{w= int, h= int, px= Buf, ok= int}
assume Image = Image_

implement img_open() = IMG(@{w= 0, h= 0, px= buf_make(4), ok= 0})

implement img_free(im) = let
  val+~IMG(s) = im
in
  buf_free(s.px)
end

implement img_w(im) = case+ im of | @IMG(s) => let val v = s.w in fold@(im); v end
implement img_h(im) = case+ im of | @IMG(s) => let val v = s.h in fold@(im); v end
implement img_ok(im) = case+ im of | @IMG(s) => let val v = s.ok in fold@(im); v end
implement img_ptr(im) = case+ im of | @IMG(s) => let val v = buf_ptr(s.px) in fold@(im); v end

implement img_upload(im, r) =
  case+ im of
  | @IMG(s) => let
      val t = if s.ok = 0 then u_zero() else rend_tex_rgba(r, s.w, s.h, buf_ptr(s.px))
    in
      fold@(im); t
    end

fun read_file(path: string): Buf = let
  val sz = fs_size(path)
in
  if sz < 8 orelse sz > 8000000 then buf_make(1)
  else let
    val fd = fs_open_read(path)
    val b = buf_make(iadd(sz, 1))
  in
    if fd < 0 then b
    else let
      val n = fs_read(fd, buf_ptr(b), sz)
      val () = fs_close(fd)
      val () = buf_set_len(b, if igt(n, 0) then n else 0)
    in
      b
    end
  end
end

fun decode_any(src: !Buf, w: &int >> _, h: &int >> _): Buf =
  if ige(buf_len(src), 8) andalso ieq(buf_get(src, 0), 137) andalso ieq(buf_get(src, 1), 80) then decode_png(src, w, h)
  else if ige(buf_len(src), 4) andalso ieq(buf_get(src, 0), 255) andalso ieq(buf_get(src, 1), 216) then decode_jpg(src, w, h)
  else if ige(buf_len(src), 26) andalso ieq(buf_get(src, 0), 66) andalso ieq(buf_get(src, 1), 77) then decode_bmp(src, w, h)
  else let
    val () = w := 0
    val () = h := 0
  in
    buf_make(4)
  end

fun take_px(im: !Image): Buf =
  case+ im of
  | @IMG(s) => let
      val b = s.px
      val () = s.px := buf_make(4)
    in
      fold@(im); b
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
  end else
    case+ im of
    | @IMG(s) => let
        val old = s.px
        val () = s.px := px
        val () = s.w := w
        val () = s.h := h
        val () = s.ok := 1
        val () = fold@(im)
        val () = buf_free(old)
      in
        1
      end
end

fun fill_str(b: &Buf >> _, s: string, i: int, n: int): void =
  if ige(i, n) then ()
  else let
    val () = buf_set(b, i, c_str_byte(s, i))
  in
    fill_str(b, s, iadd(i, 1), n)
  end

fun buf_from_str_n(s: string, n: int): Buf = let
  var b = buf_make(iadd(n, 1))
  val () = fill_str(b, s, 0, n)
  val () = buf_set_len(b, n)
in
  b
end

fun write_buf(path: string, b: !Buf): int = let
  val nlen = buf_len(b)
  val p = buf_ptr(b)
  val fd = fs_open_write(path)
in
  if ilt(fd, 0) then 0
  else let
    val n = fs_write(fd, p, nlen)
    val () = fs_close(fd)
  in
    if ige(n, 0) then 1 else 0
  end
end

fun pix(im: !Image, i: int): int =
  case+ im of
  | @IMG(s) => let
      val v = buf_get(s.px, i)
    in
      fold@(im); v
    end

implement img_selftest() = let
  val pb = make_png()
  val _wp = write_buf("/tmp/anth-t.png", pb)
  val () = buf_free(pb)
  val bb = make_bmp()
  val _wb = write_buf("/tmp/anth-t.bmp", bb)
  val () = buf_free(bb)
  val im = img_open()
  val pn = img_load(im, "/tmp/anth-t.png")
  val pr = pix(im, 0)
  val pg = pix(im, 1)
  val pb2 = pix(im, 2)
  val pok = iif(ieq(pn, 1) andalso ieq(img_w(im), 1) andalso ieq(img_h(im), 1) andalso ieq(pr, 10) andalso ieq(pg, 20) andalso ieq(pb2, 30), 1, 0)
  val bn = img_load(im, "/tmp/anth-t.bmp")
  val br = pix(im, 0)
  val bg = pix(im, 1)
  val bb2 = pix(im, 2)
  val bok = iif(ieq(bn, 1) andalso ieq(img_w(im), 2) andalso ieq(img_h(im), 1) andalso ieq(br, 10) andalso ieq(bg, 20) andalso ieq(bb2, 30), 1, 0)
  val jb = make_jpg()
  val _wj = write_buf("/tmp/anth-t.jpg", jb)
  val () = buf_free(jb)
  val jn = img_load(im, "/tmp/anth-t.jpg")
  val jr = pix(im, 0)
  val jg = pix(im, 1)
  val jbl = pix(im, 2)
  val jok = iif(ieq(jn, 1) andalso ieq(img_w(im), 8) andalso ieq(img_h(im), 8) andalso ile(iabs(isub(jr, 40)), 30) andalso ile(iabs(isub(jg, 90)), 30) andalso ile(iabs(isub(jbl, 140)), 30), 1, 0)
  val () = println! ("png=", pok, " bmp=", bok, " jpg=", jok, " r=", jr, " g=", jg, " b=", jbl)
  val () = img_free(im)
in
  iif(ieq(pok, 1) andalso ieq(bok, 1) andalso ieq(jok, 1), 1, 0)
end

