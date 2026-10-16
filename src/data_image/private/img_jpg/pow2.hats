extern fun pow2_fuel_exhausted(n: int): int = "mac#anth_die_int"

fun pow2_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), n: int): int =
  if recfuel > 0 then (
  if n <= 0 then 1 else imul(pow2_with_fuel(recfuel - 1, n - 1), 2)
  ) else pow2_fuel_exhausted(n)

fun pow2(n: int): int = pow2_with_fuel(airlock_nat(MAX_REC_FUEL), n)

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

extern fun jbits_fuel_exhausted(src: !Buf, n: int, st: &JBit >> _, k: int, acc: int): int = "mac#anth_die_int"

fun jbits_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &JBit >> _, k: int, acc: int): int =
  if recfuel > 0 then (
    if ile(k, 0) then acc
    else let
      val bit = jbit(src, n, st)
    in
      jbits_with_fuel(recfuel - 1, src, n, st, isub(k, 1), iadd(imul(acc, 2), bit))
    end
  ) else jbits_fuel_exhausted(src, n, st, k, acc)

fun jbits(src: !Buf, n: int, st: &JBit >> _, k: int, acc: int): int = jbits_with_fuel(airlock_nat(MAX_REC_FUEL), src, n, st, k, acc)

extern fun jhdec_fuel_exhausted(src: !Buf, n: int, st: &JBit >> _, hf: !Buf, t: int, len: int, code: int, first: int, index: int): int = "mac#anth_die_int"

fun jhdec_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &JBit >> _, hf: !Buf, t: int, len: int, code: int, first: int, index: int): int =
  if recfuel > 0 then (
    if igt(len, 16) then ~1
    else let
      val bit = jbit(src, n, st)
      val code2 = iadd(imul(code, 2), bit)
      val cnt = buf_get32(hf, iadd(imul(t, 400), isub(len, 1)))
      val lim = iadd(first, cnt)
    in
      if ilt(code2, lim) then buf_get32(hf, iadd(iadd(imul(t, 400), 16), iadd(index, isub(code2, first))))
      else jhdec_with_fuel(recfuel - 1, src, n, st, hf, t, iadd(len, 1), code2, imul(lim, 2), iadd(index, cnt))
    end
  ) else jhdec_fuel_exhausted(src, n, st, hf, t, len, code, first, index)

fun jhdec(src: !Buf, n: int, st: &JBit >> _, hf: !Buf, t: int, len: int, code: int, first: int, index: int): int = jhdec_with_fuel(airlock_nat(MAX_REC_FUEL), src, n, st, hf, t, len, code, first, index)

fun jrecv(src: !Buf, n: int, st: &JBit >> _, cat: int): int =
  if ile(cat, 0) then 0
  else let
    val v = jbits(src, n, st, cat, 0)
    val half = ishl(1, isub(cat, 1))
  in
    if ilt(v, half) then iadd(isub(v, ishl(1, cat)), 1) else v
  end

extern fun zblk_fuel_exhausted(coef: !Buf, i: int): void = "mac#anth_die_void"

fun zblk_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), coef: !Buf, i: int): void =
  if recfuel > 0 then (
    if ige(i, 64) then ()
    else let
      val () = buf_set32(coef, i, 0)
    in
      zblk_with_fuel(recfuel - 1, coef, iadd(i, 1))
    end
  ) else zblk_fuel_exhausted(coef, i)

fun zblk(coef: !Buf, i: int): void = zblk_with_fuel(airlock_nat(MAX_REC_FUEL), coef, i)

fun jblk_ac_write(src: !Buf, n: int, st: &JBit >> _, coef: !Buf, k: int, s: int): int = let
  val k2 = iadd(k, ishr(s, 4))
  val v = jrecv(src, n, st, iand(s, 15))
  val () = if ilt(k2, 64) then buf_set32(coef, zig(k2), v) else ()
in
  k2
end

extern fun jblk_ac_fuel_exhausted(src: !Buf, n: int, st: &JBit >> _, hf: !Buf, coef: !Buf, act: int, k: int): void = "mac#anth_die_void"

