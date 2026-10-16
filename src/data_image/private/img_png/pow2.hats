extern fun pow2_fuel_exhausted(n: int): int = "mac#anth_die_int"

fun pow2_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), n: int): int =
  if recfuel > 0 then (
  if n <= 0 then 1 else imul(pow2_with_fuel(recfuel - 1, n - 1), 2)
  ) else pow2_fuel_exhausted(n)

fun pow2(n: int): int = pow2_with_fuel(airlock_nat(MAX_REC_FUEL), n)

fun ishl(a: int, n: int): int = imul(a, pow2(n))
fun ishr(a: int, n: int): int = if n <= 0 then a else idiv(a, ishl(1, n))
fun iand(a: int, n: int): int = anth_iand(a, n)

#define CLN 0
#define CC 32
#define CS 48
#define LN 80
#define LC 400
#define LS 416
#define DC 704
#define DS 720
#define OFS 760

typedef BitS = @{p= int, nb= int, acc= int, err= Toggle}

extern fun bzero_fuel_exhausted(b: !Buf, i: int, n: int): void = "mac#anth_die_void"

fun bzero_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, i: int, n: int): void =
  if recfuel > 0 then (
    if ige(i, n) then ()
    else let
      val () = buf_set32(b, i, 0)
    in
      bzero_with_fuel(recfuel - 1, b, iadd(i, 1), n)
    end
  ) else bzero_fuel_exhausted(b, i, n)

fun zero_buffer_range(b: !Buf, i: int, n: int): void = bzero_with_fuel(airlock_nat(MAX_REC_FUEL), b, i, n)

extern fun bitfill_fuel_exhausted(src: !Buf, n: int, st: &BitS >> _): void = "mac#anth_die_void"

fun bitfill_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _): void =
  if recfuel > 0 then (
    if ige(st.nb, 24) orelse ige(st.p, n) then ()
    else let
      val () = st.acc := iadd(st.acc, ishl(buf_get(src, st.p), st.nb))
      val () = st.nb := iadd(st.nb, 8)
      val () = st.p := iadd(st.p, 1)
    in
      bitfill_with_fuel(recfuel - 1, src, n, st)
    end
  ) else bitfill_fuel_exhausted(src, n, st)

fun bitfill(src: !Buf, n: int, st: &BitS >> _): void = bitfill_with_fuel(airlock_nat(MAX_REC_FUEL), src, n, st)

fun read_one_bit(src: !Buf, n: int, st: &BitS >> _): int = let
  val () = if ilt(st.nb, 1) then bitfill(src, n, st) else ()
in
  if ilt(st.nb, 1) then let
    val () = st.err := On
  in
    0
  end else let
    val v = iand(st.acc, 1)
    val () = st.acc := ishr(st.acc, 1)
    val () = st.nb := isub(st.nb, 1)
  in
    v
  end
end

extern fun bitsk_fuel_exhausted(src: !Buf, n: int, st: &BitS >> _, k: int, acc: int, i: int): int = "mac#anth_die_int"

fun bitsk_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _, k: int, acc: int, i: int): int =
  if recfuel > 0 then (
    if ige(i, k) then acc
    else bitsk_with_fuel(recfuel - 1, src, n, st, k, iadd(acc, imul(read_one_bit(src, n, st), ishl(1, i))), iadd(i, 1))
  ) else bitsk_fuel_exhausted(src, n, st, k, acc, i)

fun read_bits_accumulated(src: !Buf, n: int, st: &BitS >> _, k: int, acc: int, i: int): int = bitsk_with_fuel(airlock_nat(MAX_REC_FUEL), src, n, st, k, acc, i)

fun read_bits(src: !Buf, n: int, st: &BitS >> _, k: int): int =
  read_bits_accumulated(src, n, st, k, 0, 0)

fun bitalign(st: &BitS >> _): void = let
  val () = st.acc := 0
  val () = st.nb := 0
in
end

extern fun count_lens_fuel_exhausted(tab: !Buf, len0: int, nsym: int, c0: int, s: int): void = "mac#anth_die_void"

fun count_lens_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), tab: !Buf, len0: int, nsym: int, c0: int, s: int): void =
  if recfuel > 0 then (
    if ige(s, nsym) then ()
    else let
      val L = buf_get32(tab, iadd(len0, s))
      val () = if igt(L, 0) andalso ilt(L, 16) then buf_set32(tab, iadd(c0, L), iadd(buf_get32(tab, iadd(c0, L)), 1)) else ()
    in
      count_lens_with_fuel(recfuel - 1, tab, len0, nsym, c0, iadd(s, 1))
    end
  ) else count_lens_fuel_exhausted(tab, len0, nsym, c0, s)

fun count_lens(tab: !Buf, len0: int, nsym: int, c0: int, s: int): void = count_lens_with_fuel(airlock_nat(MAX_REC_FUEL), tab, len0, nsym, c0, s)

extern fun fill_offs_fuel_exhausted(tab: !Buf, c0: int, len: int): void = "mac#anth_die_void"

fun fill_offs_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), tab: !Buf, c0: int, len: int): void =
  if recfuel > 0 then (
    if ige(len, 15) then ()
    else let
      val () = buf_set32(tab, iadd(OFS, iadd(len, 1)), iadd(buf_get32(tab, iadd(OFS, len)), buf_get32(tab, iadd(c0, len))))
    in
      fill_offs_with_fuel(recfuel - 1, tab, c0, iadd(len, 1))
    end
  ) else fill_offs_fuel_exhausted(tab, c0, len)

fun fill_offs(tab: !Buf, c0: int, len: int): void = fill_offs_with_fuel(airlock_nat(MAX_REC_FUEL), tab, c0, len)

extern fun place_syms_fuel_exhausted(tab: !Buf, len0: int, nsym: int, s0: int, s: int): void = "mac#anth_die_void"

fun place_syms_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), tab: !Buf, len0: int, nsym: int, s0: int, s: int): void =
  if recfuel > 0 then (
    if ige(s, nsym) then ()
    else let
      val L = buf_get32(tab, iadd(len0, s))
      val () =
        if igt(L, 0) andalso ilt(L, 16) then let
          val slot = buf_get32(tab, iadd(OFS, L))
          val () = buf_set32(tab, iadd(s0, slot), s)
          val () = buf_set32(tab, iadd(OFS, L), iadd(slot, 1))
        in
        end else ()
    in
      place_syms_with_fuel(recfuel - 1, tab, len0, nsym, s0, iadd(s, 1))
    end
  ) else place_syms_fuel_exhausted(tab, len0, nsym, s0, s)

fun place_syms(tab: !Buf, len0: int, nsym: int, s0: int, s: int): void = place_syms_with_fuel(airlock_nat(MAX_REC_FUEL), tab, len0, nsym, s0, s)

fun huff_build(tab: !Buf, len0: int, nsym: int, c0: int, s0: int): void = let
  val () = zero_buffer_range(tab, c0, iadd(c0, 16))
  val () = count_lens(tab, len0, nsym, c0, 0)
  val () = zero_buffer_range(tab, OFS, iadd(OFS, 16))
  val () = buf_set32(tab, iadd(OFS, 1), 0)
  val () = fill_offs(tab, c0, 1)
in
  place_syms(tab, len0, nsym, s0, 0)
end

extern fun hdec_go_fuel_exhausted(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, c0: int, s0: int, len: int, code: int, first: int, index: int): int = "mac#anth_die_int"

fun hdec_go_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _, tab: !Buf, c0: int, s0: int, len: int, code: int, first: int, index: int): int =
  if recfuel > 0 then (
    if igt(len, 15) orelse is_on(st.err) then ~1
    else let
      val bit = read_one_bit(src, n, st)
      val code2 = iadd(imul(code, 2), bit)
      val count = buf_get32(tab, iadd(c0, len))
      val lim = iadd(first, count)
    in
      if ilt(code2, lim) then buf_get32(tab, iadd(s0, iadd(index, isub(code2, first))))
      else hdec_go_with_fuel(recfuel - 1, src, n, st, tab, c0, s0, iadd(len, 1), code2, imul(lim, 2), iadd(index, count))
    end
  ) else hdec_go_fuel_exhausted(src, n, st, tab, c0, s0, len, code, first, index)

fun decode_huffman_code(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, c0: int, s0: int, len: int, code: int, first: int, index: int): int = hdec_go_with_fuel(airlock_nat(MAX_REC_FUEL), src, n, st, tab, c0, s0, len, code, first, index)

fun decode_huffman_symbol(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, c0: int, s0: int): int =
  decode_huffman_code(src, n, st, tab, c0, s0, 1, 0, 0, 0)

fun deflate_length_extra_bits(c: int): int =
  if ilt(c, 265) orelse ieq(c, 285) then 0 else idiv(isub(c, 261), 4)

extern fun lbase0_fuel_exhausted(e: int): int = "mac#anth_die_int"

fun lbase0_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), e: int): int =
  if recfuel > 0 then (
    if ile(e, 1) then 11 else iadd(lbase0_with_fuel(recfuel - 1, isub(e, 1)), ishl(4, isub(e, 1)))
  ) else lbase0_fuel_exhausted(e)

fun lbase0(e: int): int = lbase0_with_fuel(airlock_nat(MAX_REC_FUEL), e)

fun length_of(src: !Buf, n: int, st: &BitS >> _, c: int): int =
  if ilt(c, 265) then iadd(3, isub(c, 257))
  else if ieq(c, 285) then 258
  else let
    val e = deflate_length_extra_bits(c)
    val g = isub(c, iadd(265, imul(isub(e, 1), 4)))
    val extra = read_bits(src, n, st, e)
  in
    iadd(iadd(lbase0(e), imul(g, ishl(1, e))), extra)
  end

fun dextra(c: int): int = if ilt(c, 4) then 0 else idiv(isub(c, 2), 2)

extern fun dbase0_fuel_exhausted(e: int): int = "mac#anth_die_int"

fun dbase0_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), e: int): int =
  if recfuel > 0 then (
    if ile(e, 0) then 1
    else if ieq(e, 1) then 5
    else iadd(dbase0_with_fuel(recfuel - 1, isub(e, 1)), ishl(1, e))
  ) else dbase0_fuel_exhausted(e)

