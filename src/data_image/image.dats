#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

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

datavtype Image_ = IMG of @{w= int, h= int, px= Buf, ok= Toggle}
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
  if buf_len(src) < 4 then 0
  else if ieq(buf_get(src, 0), 137) andalso ieq(buf_get(src, 1), 80) andalso ieq(buf_get(src, 2), 78) andalso ieq(buf_get(src, 3), 71) then 1
  else if ieq(buf_get(src, 0), 66) andalso ieq(buf_get(src, 1), 77) then 2
  else if ieq(buf_get(src, 0), 255) andalso ieq(buf_get(src, 1), 216) then 3
  else 0

%{#
#include "data_image/img_jpg_prog.cats"
%}

extern fun anth_decode_jpg_fallback(buf: ptr, len: int, w: &int >> _, h: &int >> _): ptr = "mac#anth_decode_jpg_fallback"
extern fun anth_free_jpg_fallback(p: ptr): void = "mac#anth_free_jpg_fallback"
extern fun anth_jpg_ptr_is_null(p: ptr): int = "mac#anth_jpg_ptr_is_null"

fun jpg_load_fallback(src: !Buf, w: &int >> _, h: &int >> _): Buf = let
  val raw = anth_decode_jpg_fallback(buf_ptr(src), buf_len(src), w, h)
in
  if anth_jpg_ptr_is_null(raw) != 0 orelse w <= 0 orelse h <= 0 then let
    val () = w := 0
    val () = h := 0
  in
    buf_make(4)
  end else let
    val sz = imul(imul(w, h), 4)
    var dst = buf_make(sz)
    val () = buf_append(dst, raw, sz)
    val () = anth_free_jpg_fallback(raw)
  in
    dst
  end
end

fun decode_jpg_with_fallback(src: !Buf, w: &int >> _, h: &int >> _): Buf = let
  val px = decode_jpg(src, w, h)
in
  if w > 0 andalso h > 0 then px
  else let
    val () = buf_free(px)
  in
    jpg_load_fallback(src, w, h)
  end
end

fun img_decode_typed(ty: int, src: !Buf, w: &int >> _, h: &int >> _): Buf =
  if ieq(ty, 1) then decode_png(src, w, h)
  else if ieq(ty, 2) then decode_bmp(src, w, h)
  else if ieq(ty, 3) then decode_jpg_with_fallback(src, w, h)
  else buf_make(4)

fun img_downscale_if_needed(im: !Image, w: int, h: int): void =
  if w > 2048 orelse h > 2048 then let
    val rw = if w >= h then 2048 else imax(1, idiv(imul(w, 2048), h))
    val rh = if w >= h then imax(1, idiv(imul(h, 2048), w)) else 2048
  in
    seen_int(img_resize(im, rw, rh))
  end else ()

fun img_read_file(path: string, dst: &Buf >> _): bool = let
  val sz = fs_size(path)
in
  if sz <= 0 orelse sz > 33554432 then false
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
  var raw = buf_make(64)
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

extern fun resize_row_exh(src: !Buf, dst: &Buf >> _, sw: int, sh: int, tw: int, th: int, ty: int, tx: int): void = "mac#anth_die_void"

fun resize_row_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), src: !Buf, dst: &Buf >> _, sw: int, sh: int, tw: int, th: int, ty: int, tx: int
): void =
  if recfuel > 0 then (
    if ilt(tx, tw) then let
      val sx = idiv(imul(tx, sw), tw)
      val sy = idiv(imul(ty, sh), th)
      val spos = imul(iadd(imul(sy, sw), sx), 4)
      val () = resize_px_copy(src, dst, spos)
    in
      resize_row_m(recfuel - 1, src, dst, sw, sh, tw, th, ty, iadd(tx, 1))
    end else ()
  ) else resize_row_exh(src, dst, sw, sh, tw, th, ty, tx)

extern fun resize_rows_exh(src: !Buf, dst: &Buf >> _, sw: int, sh: int, tw: int, th: int, ty: int): void = "mac#anth_die_void"

fun resize_rows_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), src: !Buf, dst: &Buf >> _, sw: int, sh: int, tw: int, th: int, ty: int
): void =
  if recfuel > 0 then (
    if ilt(ty, th) then let
      val () = resize_row_m(airlock_nat(MAX_REC_FUEL), src, dst, sw, sh, tw, th, ty, 0)
    in
      resize_rows_m(recfuel - 1, src, dst, sw, sh, tw, th, iadd(ty, 1))
    end else ()
  ) else resize_rows_exh(src, dst, sw, sh, tw, th, ty)

fun img_resize_apply(im: !Image, in_w: int, in_h: int, tw: int, th: int): int = let
  val sz = imul(imul(tw, th), 4)
  var new_px = buf_make(iadd(sz, 16))
in
  case+ im of
  | @IMG(s) => let
      val () = resize_rows_m(airlock_nat(MAX_REC_FUEL), s.px, new_px, in_w, in_h, tw, th, 0)
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
  val uok = (if fs_exists(up) = 1 then img_load(im, up) else 1): int
in
  (if ieq(pn, 1) andalso ieq(bad, 0) andalso ieq(uok, 1) andalso ieq(pr, 10) andalso ieq(pg, 20) andalso ieq(pb2, 30) then 1 else 0)
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
  val rok = img_resize(im, 4, 4)
  val r_w = img_w(im)
  val r_h = img_h(im)
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
