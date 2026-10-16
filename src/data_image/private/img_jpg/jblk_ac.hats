fun jblk_ac_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &JBit >> _, hf: !Buf, coef: !Buf, act: int, k: int): void =
  if recfuel > 0 then (
    if ige(k, 64) orelse not(is_err(st.err, ErrNone)) then ()
    else let
      val s = jhdec(src, n, st, hf, act, 1, 0, 0, 0)
    in
      if ile(s, 0) then ()
      else if ieq(iand(s, 15), 0) then jblk_ac_with_fuel(recfuel - 1, src, n, st, hf, coef, act, iadd(k, 16))
      else let
        val k2 = jblk_ac_write(src, n, st, coef, k, s)
      in
        if ilt(k2, 63) then jblk_ac_with_fuel(recfuel - 1, src, n, st, hf, coef, act, iadd(k2, 1)) else ()
      end
    end
  ) else jblk_ac_fuel_exhausted(src, n, st, hf, coef, act, k)

fun jblk_ac(src: !Buf, n: int, st: &JBit >> _, hf: !Buf, coef: !Buf, act: int, k: int): void = jblk_ac_with_fuel(airlock_nat(MAX_REC_FUEL), src, n, st, hf, coef, act, k)

fun jblk(src: !Buf, n: int, st: &JBit >> _, hf: !Buf, coef: !Buf, pred: int, dct: int, act: int): int = let
  val () = zblk(coef, 0)
  val cat = jhdec(src, n, st, hf, dct, 1, 0, 0, 0)
  val dc = iadd(pred, jrecv(src, n, st, cat))
  val () = buf_set32(coef, 0, dc)
  val () = jblk_ac(src, n, st, hf, coef, act, 1)
in
  dc
end

fun dang(t: int, k: int): double =
  dmul(n_i2d(imul(iadd(imul(t, 2), 1), k)), 0.19634954084936207)

extern fun idct_uv_fuel_exhausted(coef: !Buf, q: !Buf, qbase: int, x: int, y: int, u: int, v: int, sum: double): double = "mac#anth_die_dbl"

fun idct_uv_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), coef: !Buf, q: !Buf, qbase: int, x: int, y: int, u: int, v: int, sum: double): double =
  if recfuel > 0 then (
    if ige(v, 8) then sum
    else if ige(u, 8) then idct_uv_with_fuel(recfuel - 1, coef, q, qbase, x, y, 0, iadd(v, 1), sum)
    else let
      val cu = if ieq(u, 0) then 0.7071067811865476 else 1.0
      val cv = if ieq(v, 0) then 0.7071067811865476 else 1.0
      val c = n_i2d(imul(buf_get32(coef, iadd(imul(v, 8), u)), buf_get32(q, iadd(qbase, iadd(imul(v, 8), u)))))
      val term = dmul(dmul(dmul(cu, cv), c), dmul(n_cos(dang(x, u)), n_cos(dang(y, v))))
    in
      idct_uv_with_fuel(recfuel - 1, coef, q, qbase, x, y, iadd(u, 1), v, dadd(sum, term))
    end
  ) else idct_uv_fuel_exhausted(coef, q, qbase, x, y, u, v, sum)

fun idct_uv(coef: !Buf, q: !Buf, qbase: int, x: int, y: int, u: int, v: int, sum: double): double = idct_uv_with_fuel(airlock_nat(MAX_REC_FUEL), coef, q, qbase, x, y, u, v, sum)

extern fun idct_store_fuel_exhausted(out: !Buf, obase: int, coef: !Buf, q: !Buf, qbase: int, x: int, y: int): void = "mac#anth_die_void"

fun idct_store_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), out: !Buf, obase: int, coef: !Buf, q: !Buf, qbase: int, x: int, y: int): void =
  if recfuel > 0 then (
    if ige(y, 8) then ()
    else if ige(x, 8) then idct_store_with_fuel(recfuel - 1, out, obase, coef, q, qbase, 0, iadd(y, 1))
    else let
      val pix = clamp255(dadd(ddiv(idct_uv(coef, q, qbase, x, y, 0, 0, 0.0), 4.0), 128.0))
      val () = buf_set32(out, iadd(obase, iadd(imul(y, 8), x)), pix)
    in
      idct_store_with_fuel(recfuel - 1, out, obase, coef, q, qbase, iadd(x, 1), y)
    end
  ) else idct_store_fuel_exhausted(out, obase, coef, q, qbase, x, y)

fun idct_store(out: !Buf, obase: int, coef: !Buf, q: !Buf, qbase: int, x: int, y: int): void = idct_store_with_fuel(airlock_nat(MAX_REC_FUEL), out, obase, coef, q, qbase, x, y)

extern fun sum16_fuel_exhausted(src: !Buf, j: int, i: int, a: int): int = "mac#anth_die_int"

fun sum16_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, j: int, i: int, a: int): int =
  if recfuel > 0 then (
    if ige(i, 16) then a
    else sum16_with_fuel(recfuel - 1, src, j, iadd(i, 1), iadd(a, buf_get(src, iadd(j, i))))
  ) else sum16_fuel_exhausted(src, j, i, a)

fun sum16(src: !Buf, j: int, i: int, a: int): int = sum16_with_fuel(airlock_nat(MAX_REC_FUEL), src, j, i, a)

extern fun copy_counts_fuel_exhausted(src: !Buf, hf: !Buf, t: int, j: int, i: int): void = "mac#anth_die_void"

fun copy_counts_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, hf: !Buf, t: int, j: int, i: int): void =
  if recfuel > 0 then (
    if ige(i, 16) then ()
    else let
      val () = buf_set32(hf, iadd(imul(t, 400), i), buf_get(src, iadd(j, i)))
    in
      copy_counts_with_fuel(recfuel - 1, src, hf, t, j, iadd(i, 1))
    end
  ) else copy_counts_fuel_exhausted(src, hf, t, j, i)

fun copy_counts(src: !Buf, hf: !Buf, t: int, j: int, i: int): void = copy_counts_with_fuel(airlock_nat(MAX_REC_FUEL), src, hf, t, j, i)

extern fun copy_syms_fuel_exhausted(src: !Buf, hf: !Buf, t: int, j: int, i: int, nsym: int): void = "mac#anth_die_void"

fun copy_syms_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, hf: !Buf, t: int, j: int, i: int, nsym: int): void =
  if recfuel > 0 then (
    if ige(i, nsym) then ()
    else let
      val () = buf_set32(hf, iadd(iadd(imul(t, 400), 16), i), buf_get(src, iadd(j, i)))
    in
      copy_syms_with_fuel(recfuel - 1, src, hf, t, j, iadd(i, 1), nsym)
    end
  ) else copy_syms_fuel_exhausted(src, hf, t, j, i, nsym)

fun copy_syms(src: !Buf, hf: !Buf, t: int, j: int, i: int, nsym: int): void = copy_syms_with_fuel(airlock_nat(MAX_REC_FUEL), src, hf, t, j, i, nsym)

extern fun dht_load_fuel_exhausted(src: !Buf, hf: !Buf, j: int, endp: int): void = "mac#anth_die_void"

fun dht_load_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, hf: !Buf, j: int, endp: int): void =
  if recfuel > 0 then (
    if ige(iadd(j, 17), endp) then ()
    else let
      val info = buf_get(src, j)
      val t = iadd(imul(ishr(info, 4), 2), iand(info, 15))
      val nsym = sum16(src, iadd(j, 1), 0, 0)
      val () = if ilt(t, 4) then copy_counts(src, hf, t, iadd(j, 1), 0) else ()
      val () = if ilt(t, 4) then copy_syms(src, hf, t, iadd(j, 17), 0, nsym) else ()
    in
      dht_load_with_fuel(recfuel - 1, src, hf, iadd(j, iadd(17, nsym)), endp)
    end
  ) else dht_load_fuel_exhausted(src, hf, j, endp)

fun dht_load(src: !Buf, hf: !Buf, j: int, endp: int): void = dht_load_with_fuel(airlock_nat(MAX_REC_FUEL), src, hf, j, endp)

extern fun dqt_bytes_fuel_exhausted(src: !Buf, qt: !Buf, tid: int, j: int, k: int): void = "mac#anth_die_void"

fun dqt_bytes_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, qt: !Buf, tid: int, j: int, k: int): void =
  if recfuel > 0 then (
    if ige(k, 64) then ()
    else let
      val () = buf_set32(qt, iadd(imul(tid, 64), k), buf_get(src, iadd(j, k)))
    in
      dqt_bytes_with_fuel(recfuel - 1, src, qt, tid, j, iadd(k, 1))
    end
  ) else dqt_bytes_fuel_exhausted(src, qt, tid, j, k)

fun dqt_bytes(src: !Buf, qt: !Buf, tid: int, j: int, k: int): void = dqt_bytes_with_fuel(airlock_nat(MAX_REC_FUEL), src, qt, tid, j, k)

extern fun dqt_words_fuel_exhausted(src: !Buf, qt: !Buf, tid: int, j: int, k: int): void = "mac#anth_die_void"

fun dqt_words_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, qt: !Buf, tid: int, j: int, k: int): void =
  if recfuel > 0 then (
    if ige(k, 64) then ()
    else let
      val () = buf_set32(qt, iadd(imul(tid, 64), k), be16(src, iadd(j, imul(k, 2))))
    in
      dqt_words_with_fuel(recfuel - 1, src, qt, tid, j, iadd(k, 1))
    end
  ) else dqt_words_fuel_exhausted(src, qt, tid, j, k)

fun dqt_words(src: !Buf, qt: !Buf, tid: int, j: int, k: int): void = dqt_words_with_fuel(airlock_nat(MAX_REC_FUEL), src, qt, tid, j, k)

datatype QtPrec = QtByte | QtWord

fun prec_of(n: int): QtPrec = if ieq(n, 0) then QtByte() else QtWord()

fun prec_step(p: QtPrec): int = case+ p of
  | QtByte() => 65
  | QtWord() => 129

extern fun dqt_load_fuel_exhausted(src: !Buf, qt: !Buf, j: int, endp: int): void = "mac#anth_die_void"

fun dqt_load_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, qt: !Buf, j: int, endp: int): void =
  if recfuel > 0 then (
    if ige(j, endp) then ()
    else let
      val info = buf_get(src, j)
      val tid = iand(info, 15)
      val prec = prec_of(ishr(info, 4))
      val step = prec_step(prec)
      val () = if igt(tid, 3) then ()
        else case+ prec of
          | QtByte() => dqt_bytes(src, qt, tid, iadd(j, 1), 0)
          | QtWord() => dqt_words(src, qt, tid, iadd(j, 1), 0)
    in
      dqt_load_with_fuel(recfuel - 1, src, qt, iadd(j, step), endp)
    end
  ) else dqt_load_fuel_exhausted(src, qt, j, endp)

fun dqt_load(src: !Buf, qt: !Buf, j: int, endp: int): void = dqt_load_with_fuel(airlock_nat(MAX_REC_FUEL), src, qt, j, endp)

extern fun sof_one_fuel_exhausted(src: !Buf, meta: !Buf, base: int, n: int, i: int): void = "mac#anth_die_void"

fun sof_one_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, meta: !Buf, base: int, n: int, i: int): void =
  if recfuel > 0 then (
    if ige(i, n) then ()
    else let
      val at = iadd(base, imul(i, 3))
      val hv = buf_get(src, iadd(at, 1))
      val hs = ishr(hv, 4)
      val vs = iand(hv, 15)
      val slot = imul(i, 4)
      val () = buf_set32(meta, iadd(12, slot), buf_get(src, at))
      val () = buf_set32(meta, iadd(13, slot), hs)
      val () = buf_set32(meta, iadd(14, slot), vs)
      val () = buf_set32(meta, iadd(15, slot), buf_get(src, iadd(at, 2)))
      val () = buf_set32(meta, 3, imax(buf_get32(meta, 3), hs))
      val () = buf_set32(meta, 4, imax(buf_get32(meta, 4), vs))
    in
      sof_one_with_fuel(recfuel - 1, src, meta, base, n, iadd(i, 1))
    end
  ) else sof_one_fuel_exhausted(src, meta, base, n, i)

