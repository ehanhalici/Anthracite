extern fun paint_row_fuel_exhausted(samp: !Buf, meta: !Buf, dst: !Buf, w: int, h: int, maxh: int, maxv: int, mx: int, my: int, lx: int, ly: int, mw: int): void = "mac#anth_die_void"

fun paint_row_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), samp: !Buf, meta: !Buf, dst: !Buf, w: int, h: int, maxh: int, maxv: int, mx: int, my: int, lx: int, ly: int, mw: int): void =
  if recfuel > 0 then (
    if ilt(lx, mw) then let
      val () = paint_one(samp, meta, dst, w, h, maxh, maxv, mx, my, lx, ly)
    in
      paint_row_with_fuel(recfuel - 1, samp, meta, dst, w, h, maxh, maxv, mx, my, iadd(lx, 1), ly, mw)
    end else ()
  ) else paint_row_fuel_exhausted(samp, meta, dst, w, h, maxh, maxv, mx, my, lx, ly, mw)

extern fun paint_grid_fuel_exhausted(samp: !Buf, meta: !Buf, dst: !Buf, w: int, h: int, maxh: int, maxv: int, mx: int, my: int, ly: int, mw: int, mh: int): void = "mac#anth_die_void"

fun paint_grid_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), samp: !Buf, meta: !Buf, dst: !Buf, w: int, h: int, maxh: int, maxv: int, mx: int, my: int, ly: int, mw: int, mh: int): void =
  if recfuel > 0 then (
    if ilt(ly, mh) then let
      val () = paint_row_with_fuel(recfuel - 1, samp, meta, dst, w, h, maxh, maxv, mx, my, 0, ly, mw)
    in
      paint_grid_with_fuel(recfuel - 1, samp, meta, dst, w, h, maxh, maxv, mx, my, iadd(ly, 1), mw, mh)
    end else ()
  ) else paint_grid_fuel_exhausted(samp, meta, dst, w, h, maxh, maxv, mx, my, ly, mw, mh)

fun paint_mcu(samp: !Buf, meta: !Buf, dst: !Buf, w: int, h: int, maxh: int, maxv: int, mx: int, my: int): void = let
  val mw = imul(maxh, 8)
  val mh = imul(maxv, 8)
in
  paint_grid_with_fuel(airlock_nat(MAX_REC_FUEL), samp, meta, dst, w, h, maxh, maxv, mx, my, 0, mw, mh)
end

extern fun clear_pred_fuel_exhausted(meta: !Buf, i: int): void = "mac#anth_die_void"

fun clear_pred_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), meta: !Buf, i: int): void =
  if recfuel > 0 then (
    if ige(i, 4) then ()
    else let
      val () = buf_set32(meta, iadd(50, i), 0)
    in
      clear_pred_with_fuel(recfuel - 1, meta, iadd(i, 1))
    end
  ) else clear_pred_fuel_exhausted(meta, i)

fun clear_pred(meta: !Buf, i: int): void = clear_pred_with_fuel(airlock_nat(MAX_REC_FUEL), meta, i)

fun rest_go(src: !Buf, n: int, st: &JBit >> _, meta: !Buf): void = let
  val () = seen_buf(src)
  val () = seen_buf(meta)
  val () = st.nb := st.nb
in
end

fun rest_do(src: !Buf, n: int, st: &JBit >> _, meta: !Buf): void = let
  val () = st.nb := 0
  val () = seen_int(jbit(src, n, st))
  val () = if is_err(st.err, ErrRestart) then st.err := ErrNone() else ()
in
  clear_pred(meta, 0)
end

fun maybe_restart(src: !Buf, n: int, st: &JBit >> _, meta: !Buf, mcu_i: int): void = let
  val dri = buf_get32(meta, 6)
  val rem = if ile(dri, 0) then 1 else isub(mcu_i, imul(idiv(mcu_i, dri), dri))
  val go = not(ile(dri, 0) orelse ile(mcu_i, 0) orelse ine(rem, 0))
in
  if go then rest_do(src, n, st, meta) else rest_go(src, n, st, meta)
end

fun step_idle(src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, dst: !Buf): void = let
  val () = seen_buf(src)
  val () = seen_buf(meta)
  val () = seen_buf(hf)
  val () = seen_buf(qt)
  val () = seen_buf(coef)
  val () = seen_buf(samp)
  val () = seen_buf(dst)
  val () = st.nb := st.nb
in
end

fun step_work(src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, dst: !Buf, w: int, h: int, maxh: int, maxv: int, mx: int, my: int, mi: int): void = let
  val () = maybe_restart(src, n, st, meta, mi)
  val () = dec_slots(src, n, st, meta, hf, qt, coef, samp, 0)
in
  paint_mcu(samp, meta, dst, w, h, maxh, maxv, mx, my)
end

fun step_mcu(src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, dst: !Buf, w: int, h: int, maxh: int, maxv: int, mx: int, my: int, mi: int): void = let
  val e = st.err
in
  if is_err(e, ErrNone) then step_work(src, n, st, meta, hf, qt, coef, samp, dst, w, h, maxh, maxv, mx, my, mi) else step_idle(src, n, st, meta, hf, qt, coef, samp, dst)
end

fun mcu_grid(px: int, mdim: int): int =
  if ile(mdim, 0) then 0 else idiv(iadd(px, isub(mdim, 1)), mdim)

extern fun mcu_row_fuel_exhausted(src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, dst: !Buf, w: int, h: int, maxh: int, maxv: int, mx: int, my: int, mi: int, nx: int): int = "mac#anth_die_int"

fun mcu_row_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, dst: !Buf, w: int, h: int, maxh: int, maxv: int, mx: int, my: int, mi: int, nx: int): int =
  if recfuel > 0 then (
    if ilt(mx, nx) then let
      val () = step_mcu(src, n, st, meta, hf, qt, coef, samp, dst, w, h, maxh, maxv, mx, my, mi)
    in
      mcu_row_with_fuel(recfuel - 1, src, n, st, meta, hf, qt, coef, samp, dst, w, h, maxh, maxv, iadd(mx, 1), my, iadd(mi, 1), nx)
    end else mi
  ) else mcu_row_fuel_exhausted(src, n, st, meta, hf, qt, coef, samp, dst, w, h, maxh, maxv, mx, my, mi, nx)

extern fun mcu_grid_fuel_exhausted(src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, dst: !Buf, w: int, h: int, maxh: int, maxv: int, my: int, mi: int, nx: int, ny: int): void = "mac#anth_die_void"

fun mcu_grid_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, dst: !Buf, w: int, h: int, maxh: int, maxv: int, my: int, mi: int, nx: int, ny: int): void =
  if recfuel > 0 then (
    if ilt(my, ny) then let
      val mi2 = mcu_row_with_fuel(recfuel - 1, src, n, st, meta, hf, qt, coef, samp, dst, w, h, maxh, maxv, 0, my, mi, nx)
    in
      mcu_grid_with_fuel(recfuel - 1, src, n, st, meta, hf, qt, coef, samp, dst, w, h, maxh, maxv, iadd(my, 1), mi2, nx, ny)
    end else ()
  ) else mcu_grid_fuel_exhausted(src, n, st, meta, hf, qt, coef, samp, dst, w, h, maxh, maxv, my, mi, nx, ny)

fun decode_mcus(src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, dst: !Buf, w: int, h: int): void = let
  val maxh = buf_get32(meta, 3)
  val maxv = buf_get32(meta, 4)
  val nx = mcu_grid(w, imul(maxh, 8))
  val ny = mcu_grid(h, imul(maxv, 8))
in
  mcu_grid_with_fuel(airlock_nat(MAX_REC_FUEL), src, n, st, meta, hf, qt, coef, samp, dst, w, h, maxh, maxv, 0, 0, nx, ny)
end

fun jpg_fit(w: int, h: int, nc: int, mh: int, mv: int): bool =
  if ile(w, 0) orelse ile(h, 0) orelse ile(nc, 0) then false
  else if igt(w, 8192) orelse igt(h, 8192) orelse igt(imul(w, h), 1048576) then false
  else if ilt(mh, 1) orelse igt(mh, 2) orelse ilt(mv, 1) orelse igt(mv, 2) then false
  else true

fun jpg_parse(src: !Buf, meta: !Buf, qt: !Buf, hf: !Buf): bool = let
  val () = buf_zero(meta)
  val () = buf_zero(qt)
  val () = buf_zero(hf)
in
  ieq(jmarkers(src, meta, qt, hf, 0), 1)
end

fun jpg_fit_of(parsed: Toggle, meta: !Buf): bool = let
  val w = buf_get32(meta, 0)
  val h = buf_get32(meta, 1)
  val nc = buf_get32(meta, 2)
  val mh = buf_get32(meta, 3)
  val mv = buf_get32(meta, 4)
in
  if is_on(parsed) then jpg_fit(w, h, nc, mh, mv) else false
end

fun jpg_out_buf(fit: Toggle, w: int, h: int): Buf =
  buf_make(if is_on(fit) then imax(4, imul(imul(w, h), 4)) else 4)

fun jpg_scan(src: !Buf, meta: !Buf, qt: !Buf, hf: !Buf, coef: !Buf, samp: !Buf, dst: !Buf, fit: Toggle, w: int, h: int): JpgErr = let
  var st: JBit = @{p= buf_get32(meta, 5), nb= 0, acc= 0, err= ErrNone()}
  val nsrc = buf_len(src)
  val dw = if is_on(fit) then w else 0
  val dh = if is_on(fit) then h else 0
  val () = decode_mcus(src, nsrc, st, meta, hf, qt, coef, samp, dst, dw, dh)
in
  st.err
end

fun jpg_finish(dst: Buf, fit: Toggle, w: int, h: int, err: JpgErr, wout: &int >> _, hout: &int >> _): Buf = let
  val wo = if is_on(fit) andalso is_err(err, ErrNone) then w else 0
  val ho = if is_on(fit) andalso is_err(err, ErrNone) then h else 0
  val () = wout := wo
  val () = hout := ho
  val () = if igt(wo, 0) andalso igt(ho, 0) then buf_set_len(dst, imul(imul(wo, ho), 4)) else ()
in
  if ieq(wo, 0) then let
    val () = buf_free(dst)
  in
    buf_make(JPG_FINISH_BUFFER_INITIAL_BYTES)
  end else dst
end

implement decode_jpg(src, wout, hout) = let
  var meta = buf_make(DECODE_JPG_META_INITIAL_BYTES)
  var qt = buf_make(DECODE_JPG_BUFFER_INITIAL_BYTES)
  var hf = buf_make(DECODE_JPG_BUFFER_ALTERNATE_INITIAL_BYTES)
  var coef = buf_make(DECODE_JPG_COEF_INITIAL_BYTES)
  var samp = buf_make(DECODE_JPG_SAMP_INITIAL_BYTES)
  val parsed = jpg_parse(src, meta, qt, hf)
  val fit = jpg_fit_of(toggle_of(parsed), meta)
  val w = buf_get32(meta, 0)
  val h = buf_get32(meta, 1)
  val dst = jpg_out_buf(toggle_of(fit), w, h)
  val err = jpg_scan(src, meta, qt, hf, coef, samp, dst, toggle_of(fit), w, h)
  val () = buf_free(meta)
  val () = buf_free(qt)
  val () = buf_free(hf)
  val () = buf_free(coef)
  val () = buf_free(samp)
in
  jpg_finish(dst, toggle_of(fit), w, h, err, wout, hout)
end

fun jpg_byte_0(i: int): int =
  if ieq(i, 0) then 255 else if ieq(i, 1) then 216 else if ieq(i, 2) then 255 else if ieq(i, 3) then 224 else
  if ieq(i, 4) then 0 else if ieq(i, 5) then 16 else if ieq(i, 6) then 74 else if ieq(i, 7) then 70 else
  if ieq(i, 8) then 73 else if ieq(i, 9) then 70 else if ieq(i, 10) then 0 else if ieq(i, 11) then 1 else
  if ieq(i, 12) then 1 else if ieq(i, 13) then 0 else if ieq(i, 14) then 0 else if ieq(i, 15) then 1 else
  if ieq(i, 16) then 0 else if ieq(i, 17) then 1 else if ieq(i, 18) then 0 else if ieq(i, 19) then 0 else
  if ieq(i, 20) then 255 else if ieq(i, 21) then 219 else if ieq(i, 22) then 0 else if ieq(i, 23) then 67 else
  if ieq(i, 24) then 0 else if ieq(i, 25) then 3 else if ieq(i, 26) then 2 else if ieq(i, 27) then 2 else
  if ieq(i, 28) then 3 else if ieq(i, 29) then 2 else if ieq(i, 30) then 2 else if ieq(i, 31) then 3 else
  if ieq(i, 32) then 3 else if ieq(i, 33) then 3 else if ieq(i, 34) then 3 else if ieq(i, 35) then 4 else
  if ieq(i, 36) then 3 else if ieq(i, 37) then 3 else if ieq(i, 38) then 4 else if ieq(i, 39) then 5 else
  if ieq(i, 40) then 8 else if ieq(i, 41) then 5 else if ieq(i, 42) then 5 else if ieq(i, 43) then 4 else
  if ieq(i, 44) then 4 else if ieq(i, 45) then 5 else if ieq(i, 46) then 10 else if ieq(i, 47) then 7 else
  if ieq(i, 48) then 7 else if ieq(i, 49) then 6 else if ieq(i, 50) then 8 else if ieq(i, 51) then 12 else
  if ieq(i, 52) then 10 else if ieq(i, 53) then 12 else if ieq(i, 54) then 12 else if ieq(i, 55) then 11 else
  if ieq(i, 56) then 10 else if ieq(i, 57) then 11 else if ieq(i, 58) then 11 else if ieq(i, 59) then 13 else
  if ieq(i, 60) then 14 else if ieq(i, 61) then 18 else if ieq(i, 62) then 16 else if ieq(i, 63) then 13 else
  if ieq(i, 64) then 14 else if ieq(i, 65) then 17 else if ieq(i, 66) then 14 else if ieq(i, 67) then 11 else
  if ieq(i, 68) then 11 else if ieq(i, 69) then 16 else if ieq(i, 70) then 22 else if ieq(i, 71) then 16 else
  0

