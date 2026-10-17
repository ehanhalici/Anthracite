#ifndef ANTHRACITE_STB_JPG_RESAMPLE_HATS
#define ANTHRACITE_STB_JPG_RESAMPLE_HATS

macdef YCBCR_R_CR = 1470208
macdef YCBCR_G_CR = ~748800
macdef YCBCR_G_CB = ~360960
macdef YCBCR_B_CB = 1858048

fun div4(x: int): int = ishr(x, 2)
fun div16(x: int): int = ishr(x, 4)

fun blinn_8x8(x: int, y: int): int = let
  val t = iadd(imul(x, y), 128)
in
  ishr(iadd(t, ishr(t, 8)), 8)
end

fun resample_row_1_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dst: !Buf, doff: int, src: !Buf, soff: int, w: int, i: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(i, w) then ()
    else let
      val () = buf_set(dst, iadd(doff, i), buf_get(src, iadd(soff, i)))
    in
      resample_row_1_loop(recfuel - 1, dst, doff, src, soff, w, iadd(i, 1))
    end
  ) else ()

fun resample_row_1(dst: !Buf, doff: int, src: !Buf, soff: int, w: int): void =
  resample_row_1_loop(airlock_nat(MAX_REC_FUEL), dst, doff, src, soff, w, 0)

fun resample_v2_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dst: !Buf, doff: int, src_buf: !Buf, noff: int, foff: int, w: int, i: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(i, w) then ()
    else let
      val n = buf_get(src_buf, iadd(noff, i))
      val f = buf_get(src_buf, iadd(foff, i))
      val () = buf_set(dst, iadd(doff, i), div4(iadd(iadd(imul(3, n), f), 2)))
    in
      resample_v2_loop(recfuel - 1, dst, doff, src_buf, noff, foff, w, iadd(i, 1))
    end
  ) else ()

fun resample_row_v_2(dst: !Buf, doff: int, src_buf: !Buf, noff: int, foff: int, w: int): void =
  resample_v2_loop(airlock_nat(MAX_REC_FUEL), dst, doff, src_buf, noff, foff, w, 0)

fun resample_h2_mid {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dst: !Buf, doff: int, src: !Buf, soff: int, w: int, i: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(i, isub(w, 1)) then ()
    else let
      val in_cur = buf_get(src, iadd(soff, i))
      val in_prv = buf_get(src, iadd(soff, isub(i, 1)))
      val in_nxt = buf_get(src, iadd(soff, iadd(i, 1)))
      val n = iadd(imul(3, in_cur), 2)
      val () = buf_set(dst, iadd(doff, imul(i, 2)), div4(iadd(n, in_prv)))
      val () = buf_set(dst, iadd(doff, iadd(imul(i, 2), 1)), div4(iadd(n, in_nxt)))
    in
      resample_h2_mid(recfuel - 1, dst, doff, src, soff, w, iadd(i, 1))
    end
  ) else ()

fun resample_row_h_2(dst: !Buf, doff: int, src: !Buf, soff: int, w: int): void =
  if ieq(w, 1) then let
    val v = buf_get(src, soff)
    val () = buf_set(dst, doff, v)
    val () = buf_set(dst, iadd(doff, 1), v)
  in end else let
    val v0 = buf_get(src, soff)
    val v1 = buf_get(src, iadd(soff, 1))
    val () = buf_set(dst, doff, v0)
    val () = buf_set(dst, iadd(doff, 1), div4(iadd(iadd(imul(v0, 3), v1), 2)))
    val () = resample_h2_mid(airlock_nat(MAX_REC_FUEL), dst, doff, src, soff, w, 1)
    val vn2 = buf_get(src, iadd(soff, isub(w, 2)))
    val vn1 = buf_get(src, iadd(soff, isub(w, 1)))
    val () = buf_set(dst, iadd(doff, imul(isub(w, 1), 2)), div4(iadd(iadd(imul(vn2, 3), vn1), 2)))
    val () = buf_set(dst, iadd(doff, iadd(imul(isub(w, 1), 2), 1)), vn1)
  in end

fun resample_hv2_mid {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dst: !Buf, doff: int, src_buf: !Buf, noff: int, foff: int, w: int, t_prev: int, i: int): int =
  if recursion_fuel_available(recfuel) then (
    if ige(i, w) then t_prev
    else let
      val n = buf_get(src_buf, iadd(noff, i))
      val f = buf_get(src_buf, iadd(foff, i))
      val t_cur = iadd(imul(3, n), f)
      val () = buf_set(dst, iadd(doff, isub(imul(i, 2), 1)), div16(iadd(iadd(imul(3, t_prev), t_cur), 8)))
      val () = buf_set(dst, iadd(doff, imul(i, 2)), div16(iadd(iadd(imul(3, t_cur), t_prev), 8)))
    in
      resample_hv2_mid(recfuel - 1, dst, doff, src_buf, noff, foff, w, t_cur, iadd(i, 1))
    end
  ) else t_prev

fun resample_row_hv_2(dst: !Buf, doff: int, src_buf: !Buf, noff: int, foff: int, w: int): void =
  if ieq(w, 1) then let
    val n = buf_get(src_buf, noff)
    val f = buf_get(src_buf, foff)
    val v = div4(iadd(iadd(imul(3, n), f), 2))
    val () = buf_set(dst, doff, v)
    val () = buf_set(dst, iadd(doff, 1), v)
  in end else let
    val n0 = buf_get(src_buf, noff)
    val f0 = buf_get(src_buf, foff)
    val t1 = iadd(imul(3, n0), f0)
    val () = buf_set(dst, doff, div4(iadd(t1, 2)))
    val t_last = resample_hv2_mid(airlock_nat(MAX_REC_FUEL), dst, doff, src_buf, noff, foff, w, t1, 1)
    val () = buf_set(dst, iadd(doff, isub(imul(w, 2), 1)), div4(iadd(t_last, 2)))
  in end

fun resample_generic_inner {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dst: !Buf, base: int, v: int, hs: int, j: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(j, hs) then ()
    else let
      val () = buf_set(dst, iadd(base, j), v)
    in
      resample_generic_inner(recfuel - 1, dst, base, v, hs, iadd(j, 1))
    end
  ) else ()

fun resample_generic_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dst: !Buf, doff: int, src: !Buf, soff: int, w: int, hs: int, i: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(i, w) then ()
    else let
      val v = buf_get(src, iadd(soff, i))
      val () = resample_generic_inner(airlock_nat(MAX_REC_FUEL), dst, iadd(doff, imul(i, hs)), v, hs, 0)
    in
      resample_generic_loop(recfuel - 1, dst, doff, src, soff, w, hs, iadd(i, 1))
    end
  ) else ()

fun resample_row_generic(dst: !Buf, doff: int, src: !Buf, soff: int, w: int, hs: int): void =
  resample_generic_loop(airlock_nat(MAX_REC_FUEL), dst, doff, src, soff, w, hs, 0)

fun dispatch_resample_row(dst: !Buf, doff: int, src_buf: !Buf, noff: int, foff: int, w: int, hs: int, vs: int): void =
  if ieq(hs, 1) andalso ieq(vs, 1) then resample_row_1(dst, doff, src_buf, noff, w)
  else if ieq(hs, 1) andalso ieq(vs, 2) then resample_row_v_2(dst, doff, src_buf, noff, foff, w)
  else if ieq(hs, 2) andalso ieq(vs, 1) then resample_row_h_2(dst, doff, src_buf, noff, w)
  else if ieq(hs, 2) andalso ieq(vs, 2) then resample_row_hv_2(dst, doff, src_buf, noff, foff, w)
  else resample_row_generic(dst, doff, src_buf, noff, w, hs)

fun color_ycbcr_one(out: !Buf, ooff: int, y_val: int, cb_val: int, cr_val: int): void = let
  val y_fixed = iadd(ishl(y_val, 20), ishl(1, 19))
  val cr = isub(cr_val, 128)
  val cb = isub(cb_val, 128)
  val r = ashr(iadd(y_fixed, imul(cr, YCBCR_R_CR)), 20)
  val g_cb = iand(imul(cb, YCBCR_G_CB), ishl(~1, 16))
  val g = ashr(iadd(y_fixed, iadd(imul(cr, YCBCR_G_CR), g_cb)), 20)
  val b = ashr(iadd(y_fixed, imul(cb, YCBCR_B_CB)), 20)
  val () = buf_set(out, ooff, clamp255(r))
  val () = buf_set(out, iadd(ooff, 1), clamp255(g))
  val () = buf_set(out, iadd(ooff, 2), clamp255(b))
  val () = buf_set(out, iadd(ooff, 3), 255)
in end

fun ycbcr_to_rgba_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), out: !Buf, ooff: int, y_b: !Buf, yoff: int, cb_b: !Buf, cboff: int, cr_b: !Buf, croff: int, w: int, i: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(i, w) then ()
    else let
      val yv = buf_get(y_b, iadd(yoff, i))
      val cbv = buf_get(cb_b, iadd(cboff, i))
      val crv = buf_get(cr_b, iadd(croff, i))
      val () = color_ycbcr_one(out, iadd(ooff, imul(i, 4)), yv, cbv, crv)
    in
      ycbcr_to_rgba_loop(recfuel - 1, out, ooff, y_b, yoff, cb_b, cboff, cr_b, croff, w, iadd(i, 1))
    end
  ) else ()

fun ycbcr_to_rgba_row(out: !Buf, ooff: int, y_b: !Buf, yoff: int, cb_b: !Buf, cboff: int, cr_b: !Buf, croff: int, w: int): void =
  ycbcr_to_rgba_loop(airlock_nat(MAX_REC_FUEL), out, ooff, y_b, yoff, cb_b, cboff, cr_b, croff, w, 0)

fun gray_to_rgba_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), out: !Buf, ooff: int, y_b: !Buf, yoff: int, w: int, i: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(i, w) then ()
    else let
      val yv = buf_get(y_b, iadd(yoff, i))
      val dest = iadd(ooff, imul(i, 4))
      val () = buf_set(out, dest, yv)
      val () = buf_set(out, iadd(dest, 1), yv)
      val () = buf_set(out, iadd(dest, 2), yv)
      val () = buf_set(out, iadd(dest, 3), 255)
    in
      gray_to_rgba_loop(recfuel - 1, out, ooff, y_b, yoff, w, iadd(i, 1))
    end
  ) else ()

fun gray_to_rgba_row(out: !Buf, ooff: int, y_b: !Buf, yoff: int, w: int): void =
  gray_to_rgba_loop(airlock_nat(MAX_REC_FUEL), out, ooff, y_b, yoff, w, 0)

#endif
