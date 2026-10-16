fun sof_one(src: !Buf, meta: !Buf, base: int, n: int, i: int): void = sof_one_with_fuel(airlock_nat(MAX_REC_FUEL), src, meta, base, n, i)

extern fun find_comp_fuel_exhausted(meta: !Buf, cid: int, n: int, i: int): int = "mac#anth_die_int"

fun find_comp_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), meta: !Buf, cid: int, n: int, i: int): int =
  if recfuel > 0 then (
    if ige(i, n) then 0
    else if ieq(buf_get32(meta, iadd(12, imul(i, 4))), cid) then i
    else find_comp_with_fuel(recfuel - 1, meta, cid, n, iadd(i, 1))
  ) else find_comp_fuel_exhausted(meta, cid, n, i)

fun find_comp(meta: !Buf, cid: int, n: int, i: int): int = find_comp_with_fuel(airlock_nat(MAX_REC_FUEL), meta, cid, n, i)

extern fun sos_one_fuel_exhausted(src: !Buf, meta: !Buf, base: int, ncomp: int, ns: int, i: int): void = "mac#anth_die_void"

fun sos_one_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, meta: !Buf, base: int, ncomp: int, ns: int, i: int): void =
  if recfuel > 0 then (
    if ige(i, ns) then ()
    else let
      val cid = buf_get(src, iadd(base, imul(i, 2)))
      val tab = buf_get(src, iadd(base, iadd(imul(i, 2), 1)))
      val ci = find_comp(meta, cid, ncomp, 0)
      val () = buf_set32(meta, iadd(8, i), ci)
      val () = buf_set32(meta, iadd(28, imul(ci, 2)), ishr(tab, 4))
      val () = buf_set32(meta, iadd(29, imul(ci, 2)), iand(tab, 15))
    in
      sos_one_with_fuel(recfuel - 1, src, meta, base, ncomp, ns, iadd(i, 1))
    end
  ) else sos_one_fuel_exhausted(src, meta, base, ncomp, ns, i)

fun sos_one(src: !Buf, meta: !Buf, base: int, ncomp: int, ns: int, i: int): void = sos_one_with_fuel(airlock_nat(MAX_REC_FUEL), src, meta, base, ncomp, ns, i)

extern fun next_mark_fuel_exhausted(src: !Buf, p: int): int = "mac#anth_die_int"

fun next_mark_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, p: int): int =
  if recfuel > 0 then (
    if ige(p, buf_len(src)) then p
    else if ieq(buf_get(src, p), 255) then next_mark_with_fuel(recfuel - 1, src, iadd(p, 1))
    else p
  ) else next_mark_fuel_exhausted(src, p)

fun next_mark(src: !Buf, p: int): int = next_mark_with_fuel(airlock_nat(MAX_REC_FUEL), src, p)

fun jmark_sof(src: !Buf, meta: !Buf, p2: int): void = let
  val nc = buf_get(src, iadd(p2, 8))
  val () = buf_set32(meta, 0, be16(src, iadd(p2, 6)))
  val () = buf_set32(meta, 1, be16(src, iadd(p2, 4)))
  val () = buf_set32(meta, 2, nc)
  val () = buf_set32(meta, 3, 1)
  val () = buf_set32(meta, 4, 1)
in
  sof_one(src, meta, iadd(p2, 9), nc, 0)
end

fun jmark_sos(src: !Buf, meta: !Buf, pay: int, nxt: int): int = let
  val ns = buf_get(src, pay)
  val () = buf_set32(meta, 36, ns)
  val () = sos_one(src, meta, iadd(pay, 1), buf_get32(meta, 2), ns, 0)
  val () = buf_set32(meta, 5, nxt)
in
  1
end

fun jmark_store(src: !Buf, meta: !Buf, qt: !Buf, hf: !Buf, m: JpgMark, p2: int, pay: int, nxt: int): void =
  case+ m of
  | MarkSof() => jmark_sof(src, meta, p2)
  | MarkDqt() => dqt_load(src, qt, pay, nxt)
  | MarkDht() => dht_load(src, hf, pay, nxt)
  | MarkDri() => buf_set32(meta, 6, be16(src, pay))
  | MarkSoi() => ()
  | MarkEoi() => ()
  | MarkSos() => ()
  | MarkRst() => ()
  | MarkOther() => ()

extern fun jmarkers_fuel_exhausted(src: !Buf, meta: !Buf, qt: !Buf, hf: !Buf, p: int): int = "mac#anth_die_int"

fun jmarkers_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, meta: !Buf, qt: !Buf, hf: !Buf, p: int): int =
  if recfuel > 0 then (
    if ige(iadd(p, 1), buf_len(src)) then 0
    else if ine(buf_get(src, p), 255) then 0
    else let
      val p2 = next_mark(src, p)
      val m = mark_of(buf_get(src, p2))
    in
      if is_mark(m, MarkSoi) then jmarkers_with_fuel(recfuel - 1, src, meta, qt, hf, iadd(p2, 1))
      else if is_mark(m, MarkEoi) then 0
      else if is_mark(m, MarkRst) then jmarkers_with_fuel(recfuel - 1, src, meta, qt, hf, iadd(p2, 1))
      else if ige(iadd(p2, 3), buf_len(src)) then 0
      else jmark_seg(recfuel - 1, src, meta, qt, hf, p2, m)
    end
  ) else jmarkers_fuel_exhausted(src, meta, qt, hf, p)

and jmark_seg {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, meta: !Buf, qt: !Buf, hf: !Buf, p2: int, m: JpgMark): int =
  if recfuel > 0 then let
    val ln = be16(src, iadd(p2, 1))
    val nxt = iadd(p2, iadd(1, ln))
    val pay = iadd(p2, 3)
  in
    if is_mark(m, MarkSos) then jmark_sos(src, meta, pay, nxt)
    else let
      val () = jmark_store(src, meta, qt, hf, m, p2, pay, nxt)
    in
      jmarkers_with_fuel(recfuel - 1, src, meta, qt, hf, nxt)
    end
  end else 0

fun jmarkers(src: !Buf, meta: !Buf, qt: !Buf, hf: !Buf, p: int): int = jmarkers_with_fuel(airlock_nat(MAX_REC_FUEL), src, meta, qt, hf, p)

extern fun dec_comp_fuel_exhausted(src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, ci: int, hs: int, vs: int, by: int, bx: int): void = "mac#anth_die_void"

fun dec_comp_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, ci: int, hs: int, vs: int, by: int, bx: int): void =
  if recfuel > 0 then (
    if ige(by, vs) orelse not(is_err(st.err, ErrNone)) then ()
    else if ige(bx, hs) then dec_comp_with_fuel(recfuel - 1, src, n, st, meta, hf, qt, coef, samp, ci, hs, vs, iadd(by, 1), 0)
    else let
      val pred = buf_get32(meta, iadd(50, ci))
      val dct = buf_get32(meta, iadd(28, imul(ci, 2)))
      val act = iadd(2, buf_get32(meta, iadd(29, imul(ci, 2))))
      val tq = buf_get32(meta, iadd(15, imul(ci, 4)))
      val dc = jblk(src, n, st, hf, coef, pred, dct, act)
      val () = buf_set32(meta, iadd(50, ci), dc)
      val obase = imul(iadd(imul(iadd(imul(ci, 2), by), 2), bx), 64)
      val () = idct_store(samp, obase, coef, qt, imul(tq, 64), 0, 0)
    in
      dec_comp_with_fuel(recfuel - 1, src, n, st, meta, hf, qt, coef, samp, ci, hs, vs, by, iadd(bx, 1))
    end
  ) else dec_comp_fuel_exhausted(src, n, st, meta, hf, qt, coef, samp, ci, hs, vs, by, bx)

fun dec_comp(src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, ci: int, hs: int, vs: int, by: int, bx: int): void = dec_comp_with_fuel(airlock_nat(MAX_REC_FUEL), src, n, st, meta, hf, qt, coef, samp, ci, hs, vs, by, bx)

extern fun dec_slots_fuel_exhausted(src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, slot: int): void = "mac#anth_die_void"

fun dec_slots_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, slot: int): void =
  if recfuel > 0 then (
    if ige(slot, buf_get32(meta, 36)) orelse not(is_err(st.err, ErrNone)) then ()
    else let
      val ci = buf_get32(meta, iadd(8, slot))
      val hs = buf_get32(meta, iadd(13, imul(ci, 4)))
      val vs = buf_get32(meta, iadd(14, imul(ci, 4)))
      val () = dec_comp(src, n, st, meta, hf, qt, coef, samp, ci, hs, vs, 0, 0)
    in
      dec_slots_with_fuel(recfuel - 1, src, n, st, meta, hf, qt, coef, samp, iadd(slot, 1))
    end
  ) else dec_slots_fuel_exhausted(src, n, st, meta, hf, qt, coef, samp, slot)

fun dec_slots(src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, slot: int): void = dec_slots_with_fuel(airlock_nat(MAX_REC_FUEL), src, n, st, meta, hf, qt, coef, samp, slot)

fun plane_at(samp: !Buf, meta: !Buf, ci: int, maxh: int, maxv: int, lx: int, ly: int): int = let
  val hs = buf_get32(meta, iadd(13, imul(ci, 4)))
  val vs = buf_get32(meta, iadd(14, imul(ci, 4)))
  val sx = if igt(maxh, 0) then idiv(imul(lx, hs), maxh) else 0
  val sy = if igt(maxv, 0) then idiv(imul(ly, vs), maxv) else 0
  val bx = idiv(sx, 8)
  val by = idiv(sy, 8)
  val ox = isub(sx, imul(bx, 8))
  val oy = isub(sy, imul(by, 8))
in
  buf_get32(samp, iadd(imul(iadd(imul(iadd(imul(ci, 2), by), 2), bx), 64), iadd(imul(oy, 8), ox)))
end

datatype RgbChan = ChanR | ChanG | ChanB

fun color_chan(y: int, cb: int, cr: int, ch: RgbChan): int = let
  val Y = n_i2d(y)
  val Cb = n_i2d(isub(cb, 128))
  val Cr = n_i2d(isub(cr, 128))
  val v = case+ ch of
    | ChanR() => dadd(Y, dmul(1.402, Cr))
    | ChanG() => dsub(dsub(Y, dmul(0.344136, Cb)), dmul(0.714136, Cr))
    | ChanB() => dadd(Y, dmul(1.772, Cb))
in
  clamp255(v)
end

fun put_rgb(dst: !Buf, w: int, x: int, y: int, r: int, g: int, b: int): void = let
  val p = imul(iadd(imul(y, w), x), 4)
  val () = buf_set(dst, p, r)
  val () = buf_set(dst, iadd(p, 1), g)
  val () = buf_set(dst, iadd(p, 2), b)
in
  buf_set(dst, iadd(p, 3), 255)
end

fun paint_one(samp: !Buf, meta: !Buf, dst: !Buf, w: int, h: int, maxh: int, maxv: int, mx: int, my: int, lx: int, ly: int): void = let
  val ix = iadd(imul(mx, imul(maxh, 8)), lx)
  val iy = iadd(imul(my, imul(maxv, 8)), ly)
in
  if ige(ix, w) orelse ige(iy, h) then ()
  else let
    val ncomp = buf_get32(meta, 2)
    val y0 = plane_at(samp, meta, 0, maxh, maxv, lx, ly)
    val cb = if igt(ncomp, 2) then plane_at(samp, meta, 1, maxh, maxv, lx, ly) else 128
    val cr = if igt(ncomp, 2) then plane_at(samp, meta, 2, maxh, maxv, lx, ly) else 128
    val r = color_chan(y0, cb, cr, ChanR())
    val g = color_chan(y0, cb, cr, ChanG())
    val b = color_chan(y0, cb, cr, ChanB())
  in
    put_rgb(dst, w, ix, iy, r, g, b)
  end
end

