#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "core_render/render.sats"
staload "data_image/img_common.sats"
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

fun dadd(a: double, b: double): double = a + b
fun dsub(a: double, b: double): double = a - b
fun dmul(a: double, b: double): double = a * b
fun ddiv(a: double, b: double): double = a / b

datatype JpgErr = ErrNone | ErrStop | ErrRestart

fun err_code(e: JpgErr): int = case+ e of
  | ErrNone() => 0
  | ErrStop() => 1
  | ErrRestart() => 2

fun is_err(a: JpgErr, b: JpgErr): bool = err_code(a) = err_code(b)

datatype JpgMark = MarkSof | MarkDqt | MarkDht | MarkDri | MarkSoi | MarkEoi | MarkSos | MarkRst | MarkOther

fun mark_of(n: int): JpgMark =
  if ieq(n, 192) then MarkSof()
  else if ieq(n, 219) then MarkDqt()
  else if ieq(n, 196) then MarkDht()
  else if ieq(n, 221) then MarkDri()
  else if ieq(n, 216) then MarkSoi()
  else if ieq(n, 217) then MarkEoi()
  else if ieq(n, 218) then MarkSos()
  else if ige(n, 208) andalso ile(n, 215) then MarkRst()
  else MarkOther()

fun mark_code(m: JpgMark): int = case+ m of
  | MarkSof() => 192
  | MarkDqt() => 219
  | MarkDht() => 196
  | MarkDri() => 221
  | MarkSoi() => 216
  | MarkEoi() => 217
  | MarkSos() => 218
  | MarkRst() => 208
  | MarkOther() => 0

fun is_mark(a: JpgMark, b: JpgMark): bool = mark_code(a) = mark_code(b)

typedef JBit = @{p= int, nb= int, acc= int, err= JpgErr}


fun be16(src: !Buf, i: int): int =
  iadd(ishl(buf_get(src, i), 8), buf_get(src, iadd(i, 1)))

fun zig(k: int): int =
  if ieq(k, 0) then 0 else if ieq(k, 1) then 1 else if ieq(k, 2) then 8 else if ieq(k, 3) then 16 else
  if ieq(k, 4) then 9 else if ieq(k, 5) then 2 else if ieq(k, 6) then 3 else if ieq(k, 7) then 10 else
  if ieq(k, 8) then 17 else if ieq(k, 9) then 24 else if ieq(k, 10) then 32 else if ieq(k, 11) then 25 else
  if ieq(k, 12) then 18 else if ieq(k, 13) then 11 else if ieq(k, 14) then 4 else if ieq(k, 15) then 5 else
  if ieq(k, 16) then 12 else if ieq(k, 17) then 19 else if ieq(k, 18) then 26 else if ieq(k, 19) then 33 else
  if ieq(k, 20) then 40 else if ieq(k, 21) then 48 else if ieq(k, 22) then 41 else if ieq(k, 23) then 34 else
  if ieq(k, 24) then 27 else if ieq(k, 25) then 20 else if ieq(k, 26) then 13 else if ieq(k, 27) then 6 else
  if ieq(k, 28) then 7 else if ieq(k, 29) then 14 else if ieq(k, 30) then 21 else if ieq(k, 31) then 28 else
  if ieq(k, 32) then 35 else if ieq(k, 33) then 42 else if ieq(k, 34) then 49 else if ieq(k, 35) then 56 else
  if ieq(k, 36) then 57 else if ieq(k, 37) then 50 else if ieq(k, 38) then 43 else if ieq(k, 39) then 36 else
  if ieq(k, 40) then 29 else if ieq(k, 41) then 22 else if ieq(k, 42) then 15 else if ieq(k, 43) then 23 else
  if ieq(k, 44) then 30 else if ieq(k, 45) then 37 else if ieq(k, 46) then 44 else if ieq(k, 47) then 51 else
  if ieq(k, 48) then 58 else if ieq(k, 49) then 59 else if ieq(k, 50) then 52 else if ieq(k, 51) then 45 else
  if ieq(k, 52) then 38 else if ieq(k, 53) then 31 else if ieq(k, 54) then 39 else if ieq(k, 55) then 46 else
  if ieq(k, 56) then 53 else if ieq(k, 57) then 60 else if ieq(k, 58) then 61 else if ieq(k, 59) then 54 else
  if ieq(k, 60) then 47 else if ieq(k, 61) then 55 else if ieq(k, 62) then 62 else if ieq(k, 63) then 63 else
  0

fun clamp255(x: double): int = let
  val n = n_d2i(n_floor(dadd(x, 0.5)))
in
  if n < 0 then 0 else if n > 255 then 255 else n
end

fun jload_eof(st: &JBit >> _): int = let
  val () = st.err := ErrStop()
in
  0
end

fun jload_marker(src: !Buf, n: int, st: &JBit >> _): int =
  if ige(st.p, n) then jload_eof(st)
  else let
    val nx = buf_get(src, st.p)
    val () = st.p := iadd(st.p, 1)
  in
    if ieq(nx, 0) then 255
    else if is_mark(mark_of(nx), MarkRst) then let
      val () = st.err := ErrRestart()
    in
      ~1
    end else let
      val () = st.err := ErrStop()
    in
      0
    end
  end

fun jload(src: !Buf, n: int, st: &JBit >> _): int =
  if ige(st.p, n) then jload_eof(st)
  else let
    val b0 = buf_get(src, st.p)
    val () = st.p := iadd(st.p, 1)
  in
    if ine(b0, 255) then b0 else jload_marker(src, n, st)
  end

fun jbit(src: !Buf, n: int, st: &JBit >> _): int =
  if not(is_err(st.err, ErrNone)) then 0
  else if igt(st.nb, 0) then let
    val nb2 = isub(st.nb, 1)
    val () = st.nb := nb2
  in
    iand(ishr(st.acc, nb2), 1)
  end else let
    val b = jload(src, n, st)
  in
    if not(is_err(st.err, ErrNone)) then 0
    else let
      val () = st.acc := b
      val () = st.nb := 7
    in
      iand(ishr(b, 7), 1)
    end
  end

extern fun jbits_exh(src: !Buf, n: int, st: &JBit >> _, k: int, acc: int): int = "mac#anth_die_int"

fun jbits_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &JBit >> _, k: int, acc: int): int =
  if recfuel > 0 then (
    if ile(k, 0) then acc
    else let
      val bit = jbit(src, n, st)
    in
      jbits_m(recfuel - 1, src, n, st, isub(k, 1), iadd(imul(acc, 2), bit))
    end
  ) else jbits_exh(src, n, st, k, acc)

fun jbits(src: !Buf, n: int, st: &JBit >> _, k: int, acc: int): int = jbits_m(airlock_nat(MAX_REC_FUEL), src, n, st, k, acc)

extern fun jhdec_exh(src: !Buf, n: int, st: &JBit >> _, hf: !Buf, t: int, len: int, code: int, first: int, index: int): int = "mac#anth_die_int"

fun jhdec_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &JBit >> _, hf: !Buf, t: int, len: int, code: int, first: int, index: int): int =
  if recfuel > 0 then (
    if igt(len, 16) then ~1
    else let
      val bit = jbit(src, n, st)
      val code2 = iadd(imul(code, 2), bit)
      val cnt = buf_get32(hf, iadd(imul(t, 400), isub(len, 1)))
      val lim = iadd(first, cnt)
    in
      if ilt(code2, lim) then buf_get32(hf, iadd(iadd(imul(t, 400), 16), iadd(index, isub(code2, first))))
      else jhdec_m(recfuel - 1, src, n, st, hf, t, iadd(len, 1), code2, imul(lim, 2), iadd(index, cnt))
    end
  ) else jhdec_exh(src, n, st, hf, t, len, code, first, index)

fun jhdec(src: !Buf, n: int, st: &JBit >> _, hf: !Buf, t: int, len: int, code: int, first: int, index: int): int = jhdec_m(airlock_nat(MAX_REC_FUEL), src, n, st, hf, t, len, code, first, index)

fun jrecv(src: !Buf, n: int, st: &JBit >> _, cat: int): int =
  if ile(cat, 0) then 0
  else let
    val v = jbits(src, n, st, cat, 0)
    val half = ishl(1, isub(cat, 1))
  in
    if ilt(v, half) then iadd(isub(v, ishl(1, cat)), 1) else v
  end

extern fun zblk_exh(coef: !Buf, i: int): void = "mac#anth_die_void"

fun zblk_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), coef: !Buf, i: int): void =
  if recfuel > 0 then (
    if ige(i, 64) then ()
    else let
      val () = buf_set32(coef, i, 0)
    in
      zblk_m(recfuel - 1, coef, iadd(i, 1))
    end
  ) else zblk_exh(coef, i)

fun zblk(coef: !Buf, i: int): void = zblk_m(airlock_nat(MAX_REC_FUEL), coef, i)

fun jblk_ac_write(src: !Buf, n: int, st: &JBit >> _, coef: !Buf, k: int, s: int): int = let
  val k2 = iadd(k, ishr(s, 4))
  val v = jrecv(src, n, st, iand(s, 15))
  val () = if ilt(k2, 64) then buf_set32(coef, zig(k2), v) else ()
in
  k2
end

extern fun jblk_ac_exh(src: !Buf, n: int, st: &JBit >> _, hf: !Buf, coef: !Buf, act: int, k: int): void = "mac#anth_die_void"

fun jblk_ac_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &JBit >> _, hf: !Buf, coef: !Buf, act: int, k: int): void =
  if recfuel > 0 then (
    if ige(k, 64) orelse not(is_err(st.err, ErrNone)) then ()
    else let
      val s = jhdec(src, n, st, hf, act, 1, 0, 0, 0)
    in
      if ile(s, 0) then ()
      else if ieq(iand(s, 15), 0) then jblk_ac_m(recfuel - 1, src, n, st, hf, coef, act, iadd(k, 16))
      else let
        val k2 = jblk_ac_write(src, n, st, coef, k, s)
      in
        if ilt(k2, 63) then jblk_ac_m(recfuel - 1, src, n, st, hf, coef, act, iadd(k2, 1)) else ()
      end
    end
  ) else jblk_ac_exh(src, n, st, hf, coef, act, k)

fun jblk_ac(src: !Buf, n: int, st: &JBit >> _, hf: !Buf, coef: !Buf, act: int, k: int): void = jblk_ac_m(airlock_nat(MAX_REC_FUEL), src, n, st, hf, coef, act, k)

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

extern fun idct_uv_exh(coef: !Buf, q: !Buf, qbase: int, x: int, y: int, u: int, v: int, sum: double): double = "mac#anth_die_dbl"

fun idct_uv_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), coef: !Buf, q: !Buf, qbase: int, x: int, y: int, u: int, v: int, sum: double): double =
  if recfuel > 0 then (
    if ige(v, 8) then sum
    else if ige(u, 8) then idct_uv_m(recfuel - 1, coef, q, qbase, x, y, 0, iadd(v, 1), sum)
    else let
      val cu = if ieq(u, 0) then 0.7071067811865476 else 1.0
      val cv = if ieq(v, 0) then 0.7071067811865476 else 1.0
      val c = n_i2d(imul(buf_get32(coef, iadd(imul(v, 8), u)), buf_get32(q, iadd(qbase, iadd(imul(v, 8), u)))))
      val term = dmul(dmul(dmul(cu, cv), c), dmul(n_cos(dang(x, u)), n_cos(dang(y, v))))
    in
      idct_uv_m(recfuel - 1, coef, q, qbase, x, y, iadd(u, 1), v, dadd(sum, term))
    end
  ) else idct_uv_exh(coef, q, qbase, x, y, u, v, sum)

fun idct_uv(coef: !Buf, q: !Buf, qbase: int, x: int, y: int, u: int, v: int, sum: double): double = idct_uv_m(airlock_nat(MAX_REC_FUEL), coef, q, qbase, x, y, u, v, sum)

extern fun idct_store_exh(out: !Buf, obase: int, coef: !Buf, q: !Buf, qbase: int, x: int, y: int): void = "mac#anth_die_void"

fun idct_store_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), out: !Buf, obase: int, coef: !Buf, q: !Buf, qbase: int, x: int, y: int): void =
  if recfuel > 0 then (
    if ige(y, 8) then ()
    else if ige(x, 8) then idct_store_m(recfuel - 1, out, obase, coef, q, qbase, 0, iadd(y, 1))
    else let
      val pix = clamp255(dadd(ddiv(idct_uv(coef, q, qbase, x, y, 0, 0, 0.0), 4.0), 128.0))
      val () = buf_set32(out, iadd(obase, iadd(imul(y, 8), x)), pix)
    in
      idct_store_m(recfuel - 1, out, obase, coef, q, qbase, iadd(x, 1), y)
    end
  ) else idct_store_exh(out, obase, coef, q, qbase, x, y)

fun idct_store(out: !Buf, obase: int, coef: !Buf, q: !Buf, qbase: int, x: int, y: int): void = idct_store_m(airlock_nat(MAX_REC_FUEL), out, obase, coef, q, qbase, x, y)

extern fun sum16_exh(src: !Buf, j: int, i: int, a: int): int = "mac#anth_die_int"

fun sum16_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, j: int, i: int, a: int): int =
  if recfuel > 0 then (
    if ige(i, 16) then a
    else sum16_m(recfuel - 1, src, j, iadd(i, 1), iadd(a, buf_get(src, iadd(j, i))))
  ) else sum16_exh(src, j, i, a)

fun sum16(src: !Buf, j: int, i: int, a: int): int = sum16_m(airlock_nat(MAX_REC_FUEL), src, j, i, a)

extern fun copy_counts_exh(src: !Buf, hf: !Buf, t: int, j: int, i: int): void = "mac#anth_die_void"

fun copy_counts_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, hf: !Buf, t: int, j: int, i: int): void =
  if recfuel > 0 then (
    if ige(i, 16) then ()
    else let
      val () = buf_set32(hf, iadd(imul(t, 400), i), buf_get(src, iadd(j, i)))
    in
      copy_counts_m(recfuel - 1, src, hf, t, j, iadd(i, 1))
    end
  ) else copy_counts_exh(src, hf, t, j, i)

fun copy_counts(src: !Buf, hf: !Buf, t: int, j: int, i: int): void = copy_counts_m(airlock_nat(MAX_REC_FUEL), src, hf, t, j, i)

extern fun copy_syms_exh(src: !Buf, hf: !Buf, t: int, j: int, i: int, nsym: int): void = "mac#anth_die_void"

fun copy_syms_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, hf: !Buf, t: int, j: int, i: int, nsym: int): void =
  if recfuel > 0 then (
    if ige(i, nsym) then ()
    else let
      val () = buf_set32(hf, iadd(iadd(imul(t, 400), 16), i), buf_get(src, iadd(j, i)))
    in
      copy_syms_m(recfuel - 1, src, hf, t, j, iadd(i, 1), nsym)
    end
  ) else copy_syms_exh(src, hf, t, j, i, nsym)

fun copy_syms(src: !Buf, hf: !Buf, t: int, j: int, i: int, nsym: int): void = copy_syms_m(airlock_nat(MAX_REC_FUEL), src, hf, t, j, i, nsym)

extern fun dht_load_exh(src: !Buf, hf: !Buf, j: int, endp: int): void = "mac#anth_die_void"

fun dht_load_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, hf: !Buf, j: int, endp: int): void =
  if recfuel > 0 then (
    if ige(iadd(j, 17), endp) then ()
    else let
      val info = buf_get(src, j)
      val t = iadd(imul(ishr(info, 4), 2), iand(info, 15))
      val nsym = sum16(src, iadd(j, 1), 0, 0)
      val () = if ilt(t, 4) then copy_counts(src, hf, t, iadd(j, 1), 0) else ()
      val () = if ilt(t, 4) then copy_syms(src, hf, t, iadd(j, 17), 0, nsym) else ()
    in
      dht_load_m(recfuel - 1, src, hf, iadd(j, iadd(17, nsym)), endp)
    end
  ) else dht_load_exh(src, hf, j, endp)

fun dht_load(src: !Buf, hf: !Buf, j: int, endp: int): void = dht_load_m(airlock_nat(MAX_REC_FUEL), src, hf, j, endp)

extern fun dqt_bytes_exh(src: !Buf, qt: !Buf, tid: int, j: int, k: int): void = "mac#anth_die_void"

fun dqt_bytes_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, qt: !Buf, tid: int, j: int, k: int): void =
  if recfuel > 0 then (
    if ige(k, 64) then ()
    else let
      val () = buf_set32(qt, iadd(imul(tid, 64), k), buf_get(src, iadd(j, k)))
    in
      dqt_bytes_m(recfuel - 1, src, qt, tid, j, iadd(k, 1))
    end
  ) else dqt_bytes_exh(src, qt, tid, j, k)

fun dqt_bytes(src: !Buf, qt: !Buf, tid: int, j: int, k: int): void = dqt_bytes_m(airlock_nat(MAX_REC_FUEL), src, qt, tid, j, k)

extern fun dqt_words_exh(src: !Buf, qt: !Buf, tid: int, j: int, k: int): void = "mac#anth_die_void"

fun dqt_words_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, qt: !Buf, tid: int, j: int, k: int): void =
  if recfuel > 0 then (
    if ige(k, 64) then ()
    else let
      val () = buf_set32(qt, iadd(imul(tid, 64), k), be16(src, iadd(j, imul(k, 2))))
    in
      dqt_words_m(recfuel - 1, src, qt, tid, j, iadd(k, 1))
    end
  ) else dqt_words_exh(src, qt, tid, j, k)

fun dqt_words(src: !Buf, qt: !Buf, tid: int, j: int, k: int): void = dqt_words_m(airlock_nat(MAX_REC_FUEL), src, qt, tid, j, k)

datatype QtPrec = QtByte | QtWord

fun prec_of(n: int): QtPrec = if ieq(n, 0) then QtByte() else QtWord()

fun prec_step(p: QtPrec): int = case+ p of
  | QtByte() => 65
  | QtWord() => 129

extern fun dqt_load_exh(src: !Buf, qt: !Buf, j: int, endp: int): void = "mac#anth_die_void"

fun dqt_load_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, qt: !Buf, j: int, endp: int): void =
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
      dqt_load_m(recfuel - 1, src, qt, iadd(j, step), endp)
    end
  ) else dqt_load_exh(src, qt, j, endp)

fun dqt_load(src: !Buf, qt: !Buf, j: int, endp: int): void = dqt_load_m(airlock_nat(MAX_REC_FUEL), src, qt, j, endp)

extern fun sof_one_exh(src: !Buf, meta: !Buf, base: int, n: int, i: int): void = "mac#anth_die_void"

fun sof_one_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, meta: !Buf, base: int, n: int, i: int): void =
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
      sof_one_m(recfuel - 1, src, meta, base, n, iadd(i, 1))
    end
  ) else sof_one_exh(src, meta, base, n, i)

fun sof_one(src: !Buf, meta: !Buf, base: int, n: int, i: int): void = sof_one_m(airlock_nat(MAX_REC_FUEL), src, meta, base, n, i)

extern fun find_comp_exh(meta: !Buf, cid: int, n: int, i: int): int = "mac#anth_die_int"

fun find_comp_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), meta: !Buf, cid: int, n: int, i: int): int =
  if recfuel > 0 then (
    if ige(i, n) then 0
    else if ieq(buf_get32(meta, iadd(12, imul(i, 4))), cid) then i
    else find_comp_m(recfuel - 1, meta, cid, n, iadd(i, 1))
  ) else find_comp_exh(meta, cid, n, i)

fun find_comp(meta: !Buf, cid: int, n: int, i: int): int = find_comp_m(airlock_nat(MAX_REC_FUEL), meta, cid, n, i)

extern fun sos_one_exh(src: !Buf, meta: !Buf, base: int, ncomp: int, ns: int, i: int): void = "mac#anth_die_void"

fun sos_one_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, meta: !Buf, base: int, ncomp: int, ns: int, i: int): void =
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
      sos_one_m(recfuel - 1, src, meta, base, ncomp, ns, iadd(i, 1))
    end
  ) else sos_one_exh(src, meta, base, ncomp, ns, i)

fun sos_one(src: !Buf, meta: !Buf, base: int, ncomp: int, ns: int, i: int): void = sos_one_m(airlock_nat(MAX_REC_FUEL), src, meta, base, ncomp, ns, i)

extern fun next_mark_exh(src: !Buf, p: int): int = "mac#anth_die_int"

fun next_mark_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, p: int): int =
  if recfuel > 0 then (
    if ige(p, buf_len(src)) then p
    else if ieq(buf_get(src, p), 255) then next_mark_m(recfuel - 1, src, iadd(p, 1))
    else p
  ) else next_mark_exh(src, p)

fun next_mark(src: !Buf, p: int): int = next_mark_m(airlock_nat(MAX_REC_FUEL), src, p)

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

extern fun jmarkers_exh(src: !Buf, meta: !Buf, qt: !Buf, hf: !Buf, p: int): int = "mac#anth_die_int"

fun jmarkers_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, meta: !Buf, qt: !Buf, hf: !Buf, p: int): int =
  if recfuel > 0 then (
    if ige(iadd(p, 1), buf_len(src)) then 0
    else if ine(buf_get(src, p), 255) then 0
    else let
      val p2 = next_mark(src, p)
      val m = mark_of(buf_get(src, p2))
    in
      if is_mark(m, MarkSoi) then jmarkers_m(recfuel - 1, src, meta, qt, hf, iadd(p2, 1))
      else if is_mark(m, MarkEoi) then 0
      else if is_mark(m, MarkRst) then jmarkers_m(recfuel - 1, src, meta, qt, hf, iadd(p2, 1))
      else if ige(iadd(p2, 3), buf_len(src)) then 0
      else jmark_seg(recfuel - 1, src, meta, qt, hf, p2, m)
    end
  ) else jmarkers_exh(src, meta, qt, hf, p)

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
      jmarkers_m(recfuel - 1, src, meta, qt, hf, nxt)
    end
  end else 0

fun jmarkers(src: !Buf, meta: !Buf, qt: !Buf, hf: !Buf, p: int): int = jmarkers_m(airlock_nat(MAX_REC_FUEL), src, meta, qt, hf, p)

extern fun dec_comp_exh(src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, ci: int, hs: int, vs: int, by: int, bx: int): void = "mac#anth_die_void"

fun dec_comp_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, ci: int, hs: int, vs: int, by: int, bx: int): void =
  if recfuel > 0 then (
    if ige(by, vs) orelse not(is_err(st.err, ErrNone)) then ()
    else if ige(bx, hs) then dec_comp_m(recfuel - 1, src, n, st, meta, hf, qt, coef, samp, ci, hs, vs, iadd(by, 1), 0)
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
      dec_comp_m(recfuel - 1, src, n, st, meta, hf, qt, coef, samp, ci, hs, vs, by, iadd(bx, 1))
    end
  ) else dec_comp_exh(src, n, st, meta, hf, qt, coef, samp, ci, hs, vs, by, bx)

fun dec_comp(src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, ci: int, hs: int, vs: int, by: int, bx: int): void = dec_comp_m(airlock_nat(MAX_REC_FUEL), src, n, st, meta, hf, qt, coef, samp, ci, hs, vs, by, bx)

extern fun dec_slots_exh(src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, slot: int): void = "mac#anth_die_void"

fun dec_slots_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, slot: int): void =
  if recfuel > 0 then (
    if ige(slot, buf_get32(meta, 36)) orelse not(is_err(st.err, ErrNone)) then ()
    else let
      val ci = buf_get32(meta, iadd(8, slot))
      val hs = buf_get32(meta, iadd(13, imul(ci, 4)))
      val vs = buf_get32(meta, iadd(14, imul(ci, 4)))
      val () = dec_comp(src, n, st, meta, hf, qt, coef, samp, ci, hs, vs, 0, 0)
    in
      dec_slots_m(recfuel - 1, src, n, st, meta, hf, qt, coef, samp, iadd(slot, 1))
    end
  ) else dec_slots_exh(src, n, st, meta, hf, qt, coef, samp, slot)

fun dec_slots(src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, slot: int): void = dec_slots_m(airlock_nat(MAX_REC_FUEL), src, n, st, meta, hf, qt, coef, samp, slot)

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

fun paint_mcu(samp: !Buf, meta: !Buf, dst: !Buf, w: int, h: int, maxh: int, maxv: int, mx: int, my: int): void = let
  var lx: int = 0
  var ly: int = 0
  val mw = imul(maxh, 8)
  val mh = imul(maxv, 8)
in
  while (ilt(ly, mh)) (
    lx := 0;
    while (ilt(lx, mw)) (
      paint_one(samp, meta, dst, w, h, maxh, maxv, mx, my, lx, ly);
      lx := iadd(lx, 1)
    );
    ly := iadd(ly, 1)
  )
end

extern fun clear_pred_exh(meta: !Buf, i: int): void = "mac#anth_die_void"

fun clear_pred_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), meta: !Buf, i: int): void =
  if recfuel > 0 then (
    if ige(i, 4) then ()
    else let
      val () = buf_set32(meta, iadd(50, i), 0)
    in
      clear_pred_m(recfuel - 1, meta, iadd(i, 1))
    end
  ) else clear_pred_exh(meta, i)

fun clear_pred(meta: !Buf, i: int): void = clear_pred_m(airlock_nat(MAX_REC_FUEL), meta, i)

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

fun decode_mcus(src: !Buf, n: int, st: &JBit >> _, meta: !Buf, hf: !Buf, qt: !Buf, coef: !Buf, samp: !Buf, dst: !Buf, w: int, h: int): void = let
  var mx: int = 0
  var my: int = 0
  var mi: int = 0
  val maxh = buf_get32(meta, 3)
  val maxv = buf_get32(meta, 4)
  val nx = mcu_grid(w, imul(maxh, 8))
  val ny = mcu_grid(h, imul(maxv, 8))
in
  while (ilt(my, ny)) (
    mx := 0;
    while (ilt(mx, nx)) (
      step_mcu(src, n, st, meta, hf, qt, coef, samp, dst, w, h, maxh, maxv, mx, my, mi);
      mi := iadd(mi, 1);
      mx := iadd(mx, 1)
    );
    my := iadd(my, 1)
  )
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
in
  if ieq(wo, 0) then let
    val () = buf_free(dst)
  in
    buf_make(4)
  end else dst
end

implement decode_jpg(src, wout, hout) = let
  var meta = buf_make(256)
  var qt = buf_make(1024)
  var hf = buf_make(6400)
  var coef = buf_make(256)
  var samp = buf_make(4096)
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

fun jpg_byte_1(i: int): int =
  if ieq(i, 72) then 17 else if ieq(i, 73) then 19 else if ieq(i, 74) then 20 else if ieq(i, 75) then 21 else
  if ieq(i, 76) then 21 else if ieq(i, 77) then 21 else if ieq(i, 78) then 12 else if ieq(i, 79) then 15 else
  if ieq(i, 80) then 23 else if ieq(i, 81) then 24 else if ieq(i, 82) then 22 else if ieq(i, 83) then 20 else
  if ieq(i, 84) then 24 else if ieq(i, 85) then 18 else if ieq(i, 86) then 20 else if ieq(i, 87) then 21 else
  if ieq(i, 88) then 20 else if ieq(i, 89) then 255 else if ieq(i, 90) then 219 else if ieq(i, 91) then 0 else
  if ieq(i, 92) then 67 else if ieq(i, 93) then 1 else if ieq(i, 94) then 3 else if ieq(i, 95) then 4 else
  if ieq(i, 96) then 4 else if ieq(i, 97) then 5 else if ieq(i, 98) then 4 else if ieq(i, 99) then 5 else
  if ieq(i, 100) then 9 else if ieq(i, 101) then 5 else if ieq(i, 102) then 5 else if ieq(i, 103) then 9 else
  if ieq(i, 104) then 20 else if ieq(i, 105) then 13 else if ieq(i, 106) then 11 else if ieq(i, 107) then 13 else
  if ieq(i, 108) then 20 else if ieq(i, 109) then 20 else if ieq(i, 110) then 20 else if ieq(i, 111) then 20 else
  if ieq(i, 112) then 20 else if ieq(i, 113) then 20 else if ieq(i, 114) then 20 else if ieq(i, 115) then 20 else
  if ieq(i, 116) then 20 else if ieq(i, 117) then 20 else if ieq(i, 118) then 20 else if ieq(i, 119) then 20 else
  if ieq(i, 120) then 20 else if ieq(i, 121) then 20 else if ieq(i, 122) then 20 else if ieq(i, 123) then 20 else
  if ieq(i, 124) then 20 else if ieq(i, 125) then 20 else if ieq(i, 126) then 20 else if ieq(i, 127) then 20 else
  if ieq(i, 128) then 20 else if ieq(i, 129) then 20 else if ieq(i, 130) then 20 else if ieq(i, 131) then 20 else
  if ieq(i, 132) then 20 else if ieq(i, 133) then 20 else if ieq(i, 134) then 20 else if ieq(i, 135) then 20 else
  if ieq(i, 136) then 20 else if ieq(i, 137) then 20 else if ieq(i, 138) then 20 else if ieq(i, 139) then 20 else
  if ieq(i, 140) then 20 else if ieq(i, 141) then 20 else if ieq(i, 142) then 20 else if ieq(i, 143) then 20 else
  0

fun jpg_byte_2(i: int): int =
  if ieq(i, 144) then 20 else if ieq(i, 145) then 20 else if ieq(i, 146) then 20 else if ieq(i, 147) then 20 else
  if ieq(i, 148) then 20 else if ieq(i, 149) then 20 else if ieq(i, 150) then 20 else if ieq(i, 151) then 20 else
  if ieq(i, 152) then 20 else if ieq(i, 153) then 20 else if ieq(i, 154) then 20 else if ieq(i, 155) then 20 else
  if ieq(i, 156) then 20 else if ieq(i, 157) then 20 else if ieq(i, 158) then 255 else if ieq(i, 159) then 192 else
  if ieq(i, 160) then 0 else if ieq(i, 161) then 17 else if ieq(i, 162) then 8 else if ieq(i, 163) then 0 else
  if ieq(i, 164) then 8 else if ieq(i, 165) then 0 else if ieq(i, 166) then 8 else if ieq(i, 167) then 3 else
  if ieq(i, 168) then 1 else if ieq(i, 169) then 17 else if ieq(i, 170) then 0 else if ieq(i, 171) then 2 else
  if ieq(i, 172) then 17 else if ieq(i, 173) then 1 else if ieq(i, 174) then 3 else if ieq(i, 175) then 17 else
  if ieq(i, 176) then 1 else if ieq(i, 177) then 255 else if ieq(i, 178) then 196 else if ieq(i, 179) then 0 else
  if ieq(i, 180) then 31 else if ieq(i, 181) then 0 else if ieq(i, 182) then 0 else if ieq(i, 183) then 1 else
  if ieq(i, 184) then 5 else if ieq(i, 185) then 1 else if ieq(i, 186) then 1 else if ieq(i, 187) then 1 else
  if ieq(i, 188) then 1 else if ieq(i, 189) then 1 else if ieq(i, 190) then 1 else if ieq(i, 191) then 0 else
  if ieq(i, 192) then 0 else if ieq(i, 193) then 0 else if ieq(i, 194) then 0 else if ieq(i, 195) then 0 else
  if ieq(i, 196) then 0 else if ieq(i, 197) then 0 else if ieq(i, 198) then 0 else if ieq(i, 199) then 1 else
  if ieq(i, 200) then 2 else if ieq(i, 201) then 3 else if ieq(i, 202) then 4 else if ieq(i, 203) then 5 else
  if ieq(i, 204) then 6 else if ieq(i, 205) then 7 else if ieq(i, 206) then 8 else if ieq(i, 207) then 9 else
  if ieq(i, 208) then 10 else if ieq(i, 209) then 11 else if ieq(i, 210) then 255 else if ieq(i, 211) then 196 else
  if ieq(i, 212) then 0 else if ieq(i, 213) then 181 else if ieq(i, 214) then 16 else if ieq(i, 215) then 0 else
  0

fun jpg_byte_3(i: int): int =
  if ieq(i, 216) then 2 else if ieq(i, 217) then 1 else if ieq(i, 218) then 3 else if ieq(i, 219) then 3 else
  if ieq(i, 220) then 2 else if ieq(i, 221) then 4 else if ieq(i, 222) then 3 else if ieq(i, 223) then 5 else
  if ieq(i, 224) then 5 else if ieq(i, 225) then 4 else if ieq(i, 226) then 4 else if ieq(i, 227) then 0 else
  if ieq(i, 228) then 0 else if ieq(i, 229) then 1 else if ieq(i, 230) then 125 else if ieq(i, 231) then 1 else
  if ieq(i, 232) then 2 else if ieq(i, 233) then 3 else if ieq(i, 234) then 0 else if ieq(i, 235) then 4 else
  if ieq(i, 236) then 17 else if ieq(i, 237) then 5 else if ieq(i, 238) then 18 else if ieq(i, 239) then 33 else
  if ieq(i, 240) then 49 else if ieq(i, 241) then 65 else if ieq(i, 242) then 6 else if ieq(i, 243) then 19 else
  if ieq(i, 244) then 81 else if ieq(i, 245) then 97 else if ieq(i, 246) then 7 else if ieq(i, 247) then 34 else
  if ieq(i, 248) then 113 else if ieq(i, 249) then 20 else if ieq(i, 250) then 50 else if ieq(i, 251) then 129 else
  if ieq(i, 252) then 145 else if ieq(i, 253) then 161 else if ieq(i, 254) then 8 else if ieq(i, 255) then 35 else
  if ieq(i, 256) then 66 else if ieq(i, 257) then 177 else if ieq(i, 258) then 193 else if ieq(i, 259) then 21 else
  if ieq(i, 260) then 82 else if ieq(i, 261) then 209 else if ieq(i, 262) then 240 else if ieq(i, 263) then 36 else
  if ieq(i, 264) then 51 else if ieq(i, 265) then 98 else if ieq(i, 266) then 114 else if ieq(i, 267) then 130 else
  if ieq(i, 268) then 9 else if ieq(i, 269) then 10 else if ieq(i, 270) then 22 else if ieq(i, 271) then 23 else
  if ieq(i, 272) then 24 else if ieq(i, 273) then 25 else if ieq(i, 274) then 26 else if ieq(i, 275) then 37 else
  if ieq(i, 276) then 38 else if ieq(i, 277) then 39 else if ieq(i, 278) then 40 else if ieq(i, 279) then 41 else
  if ieq(i, 280) then 42 else if ieq(i, 281) then 52 else if ieq(i, 282) then 53 else if ieq(i, 283) then 54 else
  if ieq(i, 284) then 55 else if ieq(i, 285) then 56 else if ieq(i, 286) then 57 else if ieq(i, 287) then 58 else
  0

fun jpg_byte_4(i: int): int =
  if ieq(i, 288) then 67 else if ieq(i, 289) then 68 else if ieq(i, 290) then 69 else if ieq(i, 291) then 70 else
  if ieq(i, 292) then 71 else if ieq(i, 293) then 72 else if ieq(i, 294) then 73 else if ieq(i, 295) then 74 else
  if ieq(i, 296) then 83 else if ieq(i, 297) then 84 else if ieq(i, 298) then 85 else if ieq(i, 299) then 86 else
  if ieq(i, 300) then 87 else if ieq(i, 301) then 88 else if ieq(i, 302) then 89 else if ieq(i, 303) then 90 else
  if ieq(i, 304) then 99 else if ieq(i, 305) then 100 else if ieq(i, 306) then 101 else if ieq(i, 307) then 102 else
  if ieq(i, 308) then 103 else if ieq(i, 309) then 104 else if ieq(i, 310) then 105 else if ieq(i, 311) then 106 else
  if ieq(i, 312) then 115 else if ieq(i, 313) then 116 else if ieq(i, 314) then 117 else if ieq(i, 315) then 118 else
  if ieq(i, 316) then 119 else if ieq(i, 317) then 120 else if ieq(i, 318) then 121 else if ieq(i, 319) then 122 else
  if ieq(i, 320) then 131 else if ieq(i, 321) then 132 else if ieq(i, 322) then 133 else if ieq(i, 323) then 134 else
  if ieq(i, 324) then 135 else if ieq(i, 325) then 136 else if ieq(i, 326) then 137 else if ieq(i, 327) then 138 else
  if ieq(i, 328) then 146 else if ieq(i, 329) then 147 else if ieq(i, 330) then 148 else if ieq(i, 331) then 149 else
  if ieq(i, 332) then 150 else if ieq(i, 333) then 151 else if ieq(i, 334) then 152 else if ieq(i, 335) then 153 else
  if ieq(i, 336) then 154 else if ieq(i, 337) then 162 else if ieq(i, 338) then 163 else if ieq(i, 339) then 164 else
  if ieq(i, 340) then 165 else if ieq(i, 341) then 166 else if ieq(i, 342) then 167 else if ieq(i, 343) then 168 else
  if ieq(i, 344) then 169 else if ieq(i, 345) then 170 else if ieq(i, 346) then 178 else if ieq(i, 347) then 179 else
  if ieq(i, 348) then 180 else if ieq(i, 349) then 181 else if ieq(i, 350) then 182 else if ieq(i, 351) then 183 else
  if ieq(i, 352) then 184 else if ieq(i, 353) then 185 else if ieq(i, 354) then 186 else if ieq(i, 355) then 194 else
  if ieq(i, 356) then 195 else if ieq(i, 357) then 196 else if ieq(i, 358) then 197 else if ieq(i, 359) then 198 else
  0

fun jpg_byte_5(i: int): int =
  if ieq(i, 360) then 199 else if ieq(i, 361) then 200 else if ieq(i, 362) then 201 else if ieq(i, 363) then 202 else
  if ieq(i, 364) then 210 else if ieq(i, 365) then 211 else if ieq(i, 366) then 212 else if ieq(i, 367) then 213 else
  if ieq(i, 368) then 214 else if ieq(i, 369) then 215 else if ieq(i, 370) then 216 else if ieq(i, 371) then 217 else
  if ieq(i, 372) then 218 else if ieq(i, 373) then 225 else if ieq(i, 374) then 226 else if ieq(i, 375) then 227 else
  if ieq(i, 376) then 228 else if ieq(i, 377) then 229 else if ieq(i, 378) then 230 else if ieq(i, 379) then 231 else
  if ieq(i, 380) then 232 else if ieq(i, 381) then 233 else if ieq(i, 382) then 234 else if ieq(i, 383) then 241 else
  if ieq(i, 384) then 242 else if ieq(i, 385) then 243 else if ieq(i, 386) then 244 else if ieq(i, 387) then 245 else
  if ieq(i, 388) then 246 else if ieq(i, 389) then 247 else if ieq(i, 390) then 248 else if ieq(i, 391) then 249 else
  if ieq(i, 392) then 250 else if ieq(i, 393) then 255 else if ieq(i, 394) then 196 else if ieq(i, 395) then 0 else
  if ieq(i, 396) then 31 else if ieq(i, 397) then 1 else if ieq(i, 398) then 0 else if ieq(i, 399) then 3 else
  if ieq(i, 400) then 1 else if ieq(i, 401) then 1 else if ieq(i, 402) then 1 else if ieq(i, 403) then 1 else
  if ieq(i, 404) then 1 else if ieq(i, 405) then 1 else if ieq(i, 406) then 1 else if ieq(i, 407) then 1 else
  if ieq(i, 408) then 1 else if ieq(i, 409) then 0 else if ieq(i, 410) then 0 else if ieq(i, 411) then 0 else
  if ieq(i, 412) then 0 else if ieq(i, 413) then 0 else if ieq(i, 414) then 0 else if ieq(i, 415) then 1 else
  if ieq(i, 416) then 2 else if ieq(i, 417) then 3 else if ieq(i, 418) then 4 else if ieq(i, 419) then 5 else
  if ieq(i, 420) then 6 else if ieq(i, 421) then 7 else if ieq(i, 422) then 8 else if ieq(i, 423) then 9 else
  if ieq(i, 424) then 10 else if ieq(i, 425) then 11 else if ieq(i, 426) then 255 else if ieq(i, 427) then 196 else
  if ieq(i, 428) then 0 else if ieq(i, 429) then 181 else if ieq(i, 430) then 17 else if ieq(i, 431) then 0 else
  0

fun jpg_byte_6(i: int): int =
  if ieq(i, 432) then 2 else if ieq(i, 433) then 1 else if ieq(i, 434) then 2 else if ieq(i, 435) then 4 else
  if ieq(i, 436) then 4 else if ieq(i, 437) then 3 else if ieq(i, 438) then 4 else if ieq(i, 439) then 7 else
  if ieq(i, 440) then 5 else if ieq(i, 441) then 4 else if ieq(i, 442) then 4 else if ieq(i, 443) then 0 else
  if ieq(i, 444) then 1 else if ieq(i, 445) then 2 else if ieq(i, 446) then 119 else if ieq(i, 447) then 0 else
  if ieq(i, 448) then 1 else if ieq(i, 449) then 2 else if ieq(i, 450) then 3 else if ieq(i, 451) then 17 else
  if ieq(i, 452) then 4 else if ieq(i, 453) then 5 else if ieq(i, 454) then 33 else if ieq(i, 455) then 49 else
  if ieq(i, 456) then 6 else if ieq(i, 457) then 18 else if ieq(i, 458) then 65 else if ieq(i, 459) then 81 else
  if ieq(i, 460) then 7 else if ieq(i, 461) then 97 else if ieq(i, 462) then 113 else if ieq(i, 463) then 19 else
  if ieq(i, 464) then 34 else if ieq(i, 465) then 50 else if ieq(i, 466) then 129 else if ieq(i, 467) then 8 else
  if ieq(i, 468) then 20 else if ieq(i, 469) then 66 else if ieq(i, 470) then 145 else if ieq(i, 471) then 161 else
  if ieq(i, 472) then 177 else if ieq(i, 473) then 193 else if ieq(i, 474) then 9 else if ieq(i, 475) then 35 else
  if ieq(i, 476) then 51 else if ieq(i, 477) then 82 else if ieq(i, 478) then 240 else if ieq(i, 479) then 21 else
  if ieq(i, 480) then 98 else if ieq(i, 481) then 114 else if ieq(i, 482) then 209 else if ieq(i, 483) then 10 else
  if ieq(i, 484) then 22 else if ieq(i, 485) then 36 else if ieq(i, 486) then 52 else if ieq(i, 487) then 225 else
  if ieq(i, 488) then 37 else if ieq(i, 489) then 241 else if ieq(i, 490) then 23 else if ieq(i, 491) then 24 else
  if ieq(i, 492) then 25 else if ieq(i, 493) then 26 else if ieq(i, 494) then 38 else if ieq(i, 495) then 39 else
  if ieq(i, 496) then 40 else if ieq(i, 497) then 41 else if ieq(i, 498) then 42 else if ieq(i, 499) then 53 else
  if ieq(i, 500) then 54 else if ieq(i, 501) then 55 else if ieq(i, 502) then 56 else if ieq(i, 503) then 57 else
  0

fun jpg_byte_7(i: int): int =
  if ieq(i, 504) then 58 else if ieq(i, 505) then 67 else if ieq(i, 506) then 68 else if ieq(i, 507) then 69 else
  if ieq(i, 508) then 70 else if ieq(i, 509) then 71 else if ieq(i, 510) then 72 else if ieq(i, 511) then 73 else
  if ieq(i, 512) then 74 else if ieq(i, 513) then 83 else if ieq(i, 514) then 84 else if ieq(i, 515) then 85 else
  if ieq(i, 516) then 86 else if ieq(i, 517) then 87 else if ieq(i, 518) then 88 else if ieq(i, 519) then 89 else
  if ieq(i, 520) then 90 else if ieq(i, 521) then 99 else if ieq(i, 522) then 100 else if ieq(i, 523) then 101 else
  if ieq(i, 524) then 102 else if ieq(i, 525) then 103 else if ieq(i, 526) then 104 else if ieq(i, 527) then 105 else
  if ieq(i, 528) then 106 else if ieq(i, 529) then 115 else if ieq(i, 530) then 116 else if ieq(i, 531) then 117 else
  if ieq(i, 532) then 118 else if ieq(i, 533) then 119 else if ieq(i, 534) then 120 else if ieq(i, 535) then 121 else
  if ieq(i, 536) then 122 else if ieq(i, 537) then 130 else if ieq(i, 538) then 131 else if ieq(i, 539) then 132 else
  if ieq(i, 540) then 133 else if ieq(i, 541) then 134 else if ieq(i, 542) then 135 else if ieq(i, 543) then 136 else
  if ieq(i, 544) then 137 else if ieq(i, 545) then 138 else if ieq(i, 546) then 146 else if ieq(i, 547) then 147 else
  if ieq(i, 548) then 148 else if ieq(i, 549) then 149 else if ieq(i, 550) then 150 else if ieq(i, 551) then 151 else
  if ieq(i, 552) then 152 else if ieq(i, 553) then 153 else if ieq(i, 554) then 154 else if ieq(i, 555) then 162 else
  if ieq(i, 556) then 163 else if ieq(i, 557) then 164 else if ieq(i, 558) then 165 else if ieq(i, 559) then 166 else
  if ieq(i, 560) then 167 else if ieq(i, 561) then 168 else if ieq(i, 562) then 169 else if ieq(i, 563) then 170 else
  if ieq(i, 564) then 178 else if ieq(i, 565) then 179 else if ieq(i, 566) then 180 else if ieq(i, 567) then 181 else
  if ieq(i, 568) then 182 else if ieq(i, 569) then 183 else if ieq(i, 570) then 184 else if ieq(i, 571) then 185 else
  if ieq(i, 572) then 186 else if ieq(i, 573) then 194 else if ieq(i, 574) then 195 else if ieq(i, 575) then 196 else
  0

fun jpg_byte_8(i: int): int =
  if ieq(i, 576) then 197 else if ieq(i, 577) then 198 else if ieq(i, 578) then 199 else if ieq(i, 579) then 200 else
  if ieq(i, 580) then 201 else if ieq(i, 581) then 202 else if ieq(i, 582) then 210 else if ieq(i, 583) then 211 else
  if ieq(i, 584) then 212 else if ieq(i, 585) then 213 else if ieq(i, 586) then 214 else if ieq(i, 587) then 215 else
  if ieq(i, 588) then 216 else if ieq(i, 589) then 217 else if ieq(i, 590) then 218 else if ieq(i, 591) then 226 else
  if ieq(i, 592) then 227 else if ieq(i, 593) then 228 else if ieq(i, 594) then 229 else if ieq(i, 595) then 230 else
  if ieq(i, 596) then 231 else if ieq(i, 597) then 232 else if ieq(i, 598) then 233 else if ieq(i, 599) then 234 else
  if ieq(i, 600) then 242 else if ieq(i, 601) then 243 else if ieq(i, 602) then 244 else if ieq(i, 603) then 245 else
  if ieq(i, 604) then 246 else if ieq(i, 605) then 247 else if ieq(i, 606) then 248 else if ieq(i, 607) then 249 else
  if ieq(i, 608) then 250 else if ieq(i, 609) then 255 else if ieq(i, 610) then 218 else if ieq(i, 611) then 0 else
  if ieq(i, 612) then 12 else if ieq(i, 613) then 3 else if ieq(i, 614) then 1 else if ieq(i, 615) then 0 else
  if ieq(i, 616) then 2 else if ieq(i, 617) then 17 else if ieq(i, 618) then 3 else if ieq(i, 619) then 17 else
  if ieq(i, 620) then 0 else if ieq(i, 621) then 63 else if ieq(i, 622) then 0 else if ieq(i, 623) then 240 else
  if ieq(i, 624) then 42 else if ieq(i, 625) then 253 else if ieq(i, 626) then 96 else if ieq(i, 627) then 252 else
  if ieq(i, 628) then 200 else if ieq(i, 629) then 255 else if ieq(i, 630) then 217 else
  0

fun jpg_byte(i: int): int =
  if ilt(i, 72) then jpg_byte_0(i)
  else if ilt(i, 144) then jpg_byte_1(i)
  else if ilt(i, 216) then jpg_byte_2(i)
  else if ilt(i, 288) then jpg_byte_3(i)
  else if ilt(i, 360) then jpg_byte_4(i)
  else if ilt(i, 432) then jpg_byte_5(i)
  else if ilt(i, 504) then jpg_byte_6(i)
  else if ilt(i, 576) then jpg_byte_7(i)
  else jpg_byte_8(i)

extern fun push_jpg_exh(b: &Buf >> _, i: int): void = "mac#anth_die_void"

fun push_jpg_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: &Buf >> _, i: int): void =
  if recfuel > 0 then (
    if ige(i, 631) then ()
    else let
      val () = buf_push(b, jpg_byte(i))
    in
      push_jpg_m(recfuel - 1, b, iadd(i, 1))
    end
  ) else push_jpg_exh(b, i)

fun push_jpg(b: &Buf >> _, i: int): void = push_jpg_m(airlock_nat(MAX_REC_FUEL), b, i)

implement make_jpg() = let
  var jb = buf_make(640)
  val () = push_jpg(jb, 0)
in
  jb
end
