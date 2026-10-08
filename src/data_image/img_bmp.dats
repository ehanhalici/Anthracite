#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "data_image/img_common.sats"
staload "data_image/img_bmp.sats"

extern fun pow2_exh(n: int): int = "mac#anth_die_int"

fun pow2_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), n: int): int =
  if recfuel > 0 then (
  if n <= 0 then 1 else imul(pow2_m(recfuel - 1, n - 1), 2)
  ) else pow2_exh(n)

fun pow2(n: int): int = pow2_m(airlock_nat(MAX_REC_FUEL), n)

fun ishl(a: int, n: int): int = imul(a, pow2(n))
fun ishr(a: int, n: int): int = if n <= 0 then a else idiv(a, ishl(1, n))
fun iand(a: int, n: int): int = anth_iand(a, n)

fun le32(src: !Buf, i: int): int =
  iadd(buf_get(src, i), iadd(ishl(buf_get(src, iadd(i, 1)), 8), iadd(ishl(buf_get(src, iadd(i, 2)), 16), ishl(buf_get(src, iadd(i, 3)), 24))))

fun lnot3(w: int): int = iand(iadd(imul(w, 3), 3), isub(0, 4))

extern fun bmp_px_exh(src: !Buf, dst: &Buf >> _, w: int, h: int, off: int, stride: int, bottom: Toggle, x: int, y: int): void = "mac#anth_die_void"

fun bmp_px_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, dst: &Buf >> _, w: int, h: int, off: int, stride: int, bottom: Toggle, x: int, y: int): void =
  if recfuel > 0 then (
    if ige(y, h) then ()
    else if ige(x, w) then bmp_px_m(recfuel - 1, src, dst, w, h, off, stride, bottom, 0, iadd(y, 1))
    else let
      val srcy = if is_on(bottom) then isub(isub(h, 1), y) else y
      val p = iadd(off, iadd(imul(srcy, stride), imul(x, 3)))
      val () = put4(dst, buf_get(src, iadd(p, 2)), buf_get(src, iadd(p, 1)), buf_get(src, p), 255)
    in
      bmp_px_m(recfuel - 1, src, dst, w, h, off, stride, bottom, iadd(x, 1), y)
    end
  ) else bmp_px_exh(src, dst, w, h, off, stride, bottom, x, y)

fun bmp_px(src: !Buf, dst: &Buf >> _, w: int, h: int, off: int, stride: int, bottom: Toggle, x: int, y: int): void = bmp_px_m(airlock_nat(MAX_REC_FUEL), src, dst, w, h, off, stride, bottom, x, y)

fun bmp_store_size(fit: Toggle, w: int, h: int, wout: &int >> _, hout: &int >> _): void = let
  val wo = if is_on(fit) then w else 0
  val ho = if is_on(fit) then h else 0
  val () = wout := wo
  val () = hout := ho
in
end

implement decode_bmp(src, wout, hout) = let
  val w = le32(src, 18)
  val h0 = le32(src, 22)
  val bottom = if igt(h0, 0) then 1 else 0
  val h = iabs(h0)
  val off = le32(src, 10)
  val bits = iadd(buf_get(src, 28), ishl(buf_get(src, 29), 8))
  val stride = lnot3(w)
  val fit = if igt(w, 0) andalso igt(h, 0) andalso ile(w, 8192) andalso ile(h, 8192) andalso ieq(bits, 24) andalso ieq(le32(src, 30), 0) then 1 else 0
  var dst = buf_make(if ieq(fit, 1) then imax(4, imul(imul(w, h), 4)) else 4)
  val () = bmp_px(src, dst, if ieq(fit, 1) then w else 0, if ieq(fit, 1) then h else 0, off, stride, toggle_of(ieq(bottom, 1)), 0, 0)
  val () = bmp_store_size(toggle_of(ieq(fit, 1)), w, h, wout, hout)
in
  if ieq(fit, 1) then dst else let
    val () = buf_free(dst)
  in
    buf_make(4)
  end
end

fun push_le32(b: &Buf >> _, v: int): void = let
  val () = buf_push(b, iand(v, 255))
  val () = buf_push(b, iand(ishr(v, 8), 255))
  val () = buf_push(b, iand(ishr(v, 16), 255))
in
  buf_push(b, iand(ishr(v, 24), 255))
end

fun push_bmp_file_hdr(b: &Buf >> _): void = let
  val () = buf_push(b, 66)
  val () = buf_push(b, 77)
  val () = push_le32(b, 62)
  val () = push_le32(b, 0)
  val () = push_le32(b, 54)
in
end

fun push_bmp_info_hdr(b: &Buf >> _): void = let
  val () = push_le32(b, 40)
  val () = push_le32(b, 2)
  val () = push_le32(b, 1)
  val () = buf_push(b, 1)
  val () = buf_push(b, 0)
  val () = buf_push(b, 24)
  val () = buf_push(b, 0)
  val () = push_le32(b, 0)
  val () = push_le32(b, 0)
  val () = push_le32(b, 0)
  val () = push_le32(b, 0)
  val () = push_le32(b, 0)
  val () = push_le32(b, 0)
in
end

fun push_bmp_pixels(b: &Buf >> _): void = let
  val () = buf_push(b, 30)
  val () = buf_push(b, 20)
  val () = buf_push(b, 10)
  val () = buf_push(b, 30)
  val () = buf_push(b, 20)
  val () = buf_push(b, 10)
  val () = buf_push(b, 0)
  val () = buf_push(b, 0)
in
end

implement make_bmp() = let
  var b = buf_make(80)
  val () = push_bmp_file_hdr(b)
  val () = push_bmp_info_hdr(b)
  val () = push_bmp_pixels(b)
in
  b
end
