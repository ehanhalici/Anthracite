#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "data_image/img_common.sats"
staload "data_image/img_png.sats"

extern fun pow2_exh(n: int): int = "mac#anth_die_int"

fun pow2_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), n: int): int =
  if recfuel > 0 then (
  if n <= 0 then 1 else imul(pow2_m(recfuel - 1, n - 1), 2)
  ) else pow2_exh(n)

fun pow2(n: int): int = pow2_m(airlock_nat(MAX_REC_FUEL), n)

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

extern fun bzero_exh(b: !Buf, i: int, n: int): void = "mac#anth_die_void"

fun bzero_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, i: int, n: int): void =
  if recfuel > 0 then (
    if ige(i, n) then ()
    else let
      val () = buf_set32(b, i, 0)
    in
      bzero_m(recfuel - 1, b, iadd(i, 1), n)
    end
  ) else bzero_exh(b, i, n)

fun bzero(b: !Buf, i: int, n: int): void = bzero_m(airlock_nat(MAX_REC_FUEL), b, i, n)

extern fun bitfill_exh(src: !Buf, n: int, st: &BitS >> _): void = "mac#anth_die_void"

fun bitfill_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _): void =
  if recfuel > 0 then (
    if ige(st.nb, 24) orelse ige(st.p, n) then ()
    else let
      val () = st.acc := iadd(st.acc, ishl(buf_get(src, st.p), st.nb))
      val () = st.nb := iadd(st.nb, 8)
      val () = st.p := iadd(st.p, 1)
    in
      bitfill_m(recfuel - 1, src, n, st)
    end
  ) else bitfill_exh(src, n, st)

fun bitfill(src: !Buf, n: int, st: &BitS >> _): void = bitfill_m(airlock_nat(MAX_REC_FUEL), src, n, st)

fun bit1(src: !Buf, n: int, st: &BitS >> _): int = let
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

extern fun bitsk_exh(src: !Buf, n: int, st: &BitS >> _, k: int, acc: int, i: int): int = "mac#anth_die_int"

fun bitsk_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _, k: int, acc: int, i: int): int =
  if recfuel > 0 then (
    if ige(i, k) then acc
    else bitsk_m(recfuel - 1, src, n, st, k, iadd(acc, imul(bit1(src, n, st), ishl(1, i))), iadd(i, 1))
  ) else bitsk_exh(src, n, st, k, acc, i)

fun bitsk(src: !Buf, n: int, st: &BitS >> _, k: int, acc: int, i: int): int = bitsk_m(airlock_nat(MAX_REC_FUEL), src, n, st, k, acc, i)

fun bits(src: !Buf, n: int, st: &BitS >> _, k: int): int =
  bitsk(src, n, st, k, 0, 0)

fun bitalign(st: &BitS >> _): void = let
  val () = st.acc := 0
  val () = st.nb := 0
in
end

extern fun count_lens_exh(tab: !Buf, len0: int, nsym: int, c0: int, s: int): void = "mac#anth_die_void"

fun count_lens_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), tab: !Buf, len0: int, nsym: int, c0: int, s: int): void =
  if recfuel > 0 then (
    if ige(s, nsym) then ()
    else let
      val L = buf_get32(tab, iadd(len0, s))
      val () = if igt(L, 0) andalso ilt(L, 16) then buf_set32(tab, iadd(c0, L), iadd(buf_get32(tab, iadd(c0, L)), 1)) else ()
    in
      count_lens_m(recfuel - 1, tab, len0, nsym, c0, iadd(s, 1))
    end
  ) else count_lens_exh(tab, len0, nsym, c0, s)

fun count_lens(tab: !Buf, len0: int, nsym: int, c0: int, s: int): void = count_lens_m(airlock_nat(MAX_REC_FUEL), tab, len0, nsym, c0, s)

extern fun fill_offs_exh(tab: !Buf, c0: int, len: int): void = "mac#anth_die_void"

fun fill_offs_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), tab: !Buf, c0: int, len: int): void =
  if recfuel > 0 then (
    if ige(len, 15) then ()
    else let
      val () = buf_set32(tab, iadd(OFS, iadd(len, 1)), iadd(buf_get32(tab, iadd(OFS, len)), buf_get32(tab, iadd(c0, len))))
    in
      fill_offs_m(recfuel - 1, tab, c0, iadd(len, 1))
    end
  ) else fill_offs_exh(tab, c0, len)

fun fill_offs(tab: !Buf, c0: int, len: int): void = fill_offs_m(airlock_nat(MAX_REC_FUEL), tab, c0, len)

extern fun place_syms_exh(tab: !Buf, len0: int, nsym: int, s0: int, s: int): void = "mac#anth_die_void"

fun place_syms_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), tab: !Buf, len0: int, nsym: int, s0: int, s: int): void =
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
      place_syms_m(recfuel - 1, tab, len0, nsym, s0, iadd(s, 1))
    end
  ) else place_syms_exh(tab, len0, nsym, s0, s)

fun place_syms(tab: !Buf, len0: int, nsym: int, s0: int, s: int): void = place_syms_m(airlock_nat(MAX_REC_FUEL), tab, len0, nsym, s0, s)

fun huff_build(tab: !Buf, len0: int, nsym: int, c0: int, s0: int): void = let
  val () = bzero(tab, c0, iadd(c0, 16))
  val () = count_lens(tab, len0, nsym, c0, 0)
  val () = bzero(tab, OFS, iadd(OFS, 16))
  val () = buf_set32(tab, iadd(OFS, 1), 0)
  val () = fill_offs(tab, c0, 1)
in
  place_syms(tab, len0, nsym, s0, 0)
end

extern fun hdec_go_exh(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, c0: int, s0: int, len: int, code: int, first: int, index: int): int = "mac#anth_die_int"

fun hdec_go_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _, tab: !Buf, c0: int, s0: int, len: int, code: int, first: int, index: int): int =
  if recfuel > 0 then (
    if igt(len, 15) orelse is_on(st.err) then ~1
    else let
      val bit = bit1(src, n, st)
      val code2 = iadd(imul(code, 2), bit)
      val count = buf_get32(tab, iadd(c0, len))
      val lim = iadd(first, count)
    in
      if ilt(code2, lim) then buf_get32(tab, iadd(s0, iadd(index, isub(code2, first))))
      else hdec_go_m(recfuel - 1, src, n, st, tab, c0, s0, iadd(len, 1), code2, imul(lim, 2), iadd(index, count))
    end
  ) else hdec_go_exh(src, n, st, tab, c0, s0, len, code, first, index)

fun hdec_go(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, c0: int, s0: int, len: int, code: int, first: int, index: int): int = hdec_go_m(airlock_nat(MAX_REC_FUEL), src, n, st, tab, c0, s0, len, code, first, index)

fun hdec(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, c0: int, s0: int): int =
  hdec_go(src, n, st, tab, c0, s0, 1, 0, 0, 0)

fun lextra(c: int): int =
  if ilt(c, 265) orelse ieq(c, 285) then 0 else idiv(isub(c, 261), 4)

extern fun lbase0_exh(e: int): int = "mac#anth_die_int"

fun lbase0_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), e: int): int =
  if recfuel > 0 then (
    if ile(e, 1) then 11 else iadd(lbase0_m(recfuel - 1, isub(e, 1)), ishl(4, isub(e, 1)))
  ) else lbase0_exh(e)

fun lbase0(e: int): int = lbase0_m(airlock_nat(MAX_REC_FUEL), e)

fun length_of(src: !Buf, n: int, st: &BitS >> _, c: int): int =
  if ilt(c, 265) then iadd(3, isub(c, 257))
  else if ieq(c, 285) then 258
  else let
    val e = lextra(c)
    val g = isub(c, iadd(265, imul(isub(e, 1), 4)))
    val extra = bits(src, n, st, e)
  in
    iadd(iadd(lbase0(e), imul(g, ishl(1, e))), extra)
  end

fun dextra(c: int): int = if ilt(c, 4) then 0 else idiv(isub(c, 2), 2)

extern fun dbase0_exh(e: int): int = "mac#anth_die_int"

fun dbase0_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), e: int): int =
  if recfuel > 0 then (
    if ile(e, 0) then 1
    else if ieq(e, 1) then 5
    else iadd(dbase0_m(recfuel - 1, isub(e, 1)), ishl(1, e))
  ) else dbase0_exh(e)

fun dbase0(e: int): int = dbase0_m(airlock_nat(MAX_REC_FUEL), e)

fun dist_of(src: !Buf, n: int, st: &BitS >> _, c: int): int =
  if ilt(c, 4) then iadd(c, 1)
  else let
    val e = dextra(c)
    val g = isub(c, iadd(2, imul(e, 2)))
    val extra = bits(src, n, st, e)
  in
    iadd(iadd(dbase0(e), imul(g, ishl(1, e))), extra)
  end

extern fun copy_out_exh(dst: &Buf >> _, dist: int, len: int, i: int): void = "mac#anth_die_void"

fun copy_out_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dst: &Buf >> _, dist: int, len: int, i: int): void =
  if recfuel > 0 then (
    if ige(i, len) then ()
    else let
      val n0 = buf_len(dst)
      val by = buf_get(dst, isub(n0, dist))
      val () = buf_push(dst, by)
    in
      copy_out_m(recfuel - 1, dst, dist, len, iadd(i, 1))
    end
  ) else copy_out_exh(dst, dist, len, i)

fun copy_out(dst: &Buf >> _, dist: int, len: int, i: int): void = copy_out_m(airlock_nat(MAX_REC_FUEL), dst, dist, len, i)

datatype DeflateSym = SymBad | SymEnd | SymLit | SymLen

fun sym_kind(s: int): DeflateSym =
  if ilt(s, 0) then SymBad()
  else if ieq(s, 256) then SymEnd()
  else if ilt(s, 256) then SymLit()
  else SymLen()

extern fun symloop_exh(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, dst: &Buf >> _): int = "mac#anth_die_int"

fun symloop_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _, tab: !Buf, dst: &Buf >> _): int =
  if recfuel > 0 then (
    if igt(buf_len(dst), 16000000) orelse is_on(st.err) then 0
    else let
      val s = hdec(src, n, st, tab, LC, LS)
      val k = sym_kind(s)
    in
      case+ k of
      | SymBad() => 0
      | SymEnd() => 1
      | SymLit() => let
          val () = buf_push(dst, s)
        in
          symloop_m(recfuel - 1, src, n, st, tab, dst)
        end
      | SymLen() => sym_copy(recfuel - 1, src, n, st, tab, dst, s)
    end
  ) else symloop_exh(src, n, st, tab, dst)

and sym_copy {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _, tab: !Buf, dst: &Buf >> _, s: int): int =
  if recfuel > 0 then let
    val ln = length_of(src, n, st, s)
    val dc = hdec(src, n, st, tab, DC, DS)
    val dist = dist_of(src, n, st, dc)
  in
    if ile(dist, 0) orelse igt(dist, buf_len(dst)) then 0
    else let
      val () = copy_out(dst, dist, ln, 0)
    in
      symloop_m(recfuel - 1, src, n, st, tab, dst)
    end
  end else 0

fun symloop(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, dst: &Buf >> _): int = symloop_m(airlock_nat(MAX_REC_FUEL), src, n, st, tab, dst)

extern fun set_fixed_exh(tab: !Buf, i: int): void = "mac#anth_die_void"

fun set_fixed_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), tab: !Buf, i: int): void =
  if recfuel > 0 then (
    if ige(i, 288) then ()
    else let
      val L = if ilt(i, 144) then 8 else if ilt(i, 256) then 9 else if ilt(i, 280) then 7 else 8
      val () = buf_set32(tab, iadd(LN, i), L)
    in
      set_fixed_m(recfuel - 1, tab, iadd(i, 1))
    end
  ) else set_fixed_exh(tab, i)

fun set_fixed(tab: !Buf, i: int): void = set_fixed_m(airlock_nat(MAX_REC_FUEL), tab, i)

extern fun set_dist5_exh(tab: !Buf, i: int): void = "mac#anth_die_void"

fun set_dist5_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), tab: !Buf, i: int): void =
  if recfuel > 0 then (
    if ige(i, 32) then ()
    else let
      val () = buf_set32(tab, iadd(iadd(LN, 288), i), 5)
    in
      set_dist5_m(recfuel - 1, tab, iadd(i, 1))
    end
  ) else set_dist5_exh(tab, i)

fun set_dist5(tab: !Buf, i: int): void = set_dist5_m(airlock_nat(MAX_REC_FUEL), tab, i)

fun cl_order(i: int): int =
  if ieq(i, 0) then 16
  else if ieq(i, 1) then 17
  else if ieq(i, 2) then 18
  else if ieq(i, 3) then 0
  else if ieq(i, 4) then 8
  else if ieq(i, 5) then 7
  else if ieq(i, 6) then 9
  else if ieq(i, 7) then 6
  else if ieq(i, 8) then 10
  else if ieq(i, 9) then 5
  else if ieq(i, 10) then 11
  else if ieq(i, 11) then 4
  else if ieq(i, 12) then 12
  else if ieq(i, 13) then 3
  else if ieq(i, 14) then 13
  else if ieq(i, 15) then 2
  else if ieq(i, 16) then 14
  else if ieq(i, 17) then 1
  else 15

extern fun read_cl_exh(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, ncl: int, i: int): void = "mac#anth_die_void"

fun read_cl_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _, tab: !Buf, ncl: int, i: int): void =
  if recfuel > 0 then (
    if ige(i, ncl) then ()
    else let
      val () = buf_set32(tab, iadd(CLN, cl_order(i)), bits(src, n, st, 3))
    in
      read_cl_m(recfuel - 1, src, n, st, tab, ncl, iadd(i, 1))
    end
  ) else read_cl_exh(src, n, st, tab, ncl, i)

fun read_cl(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, ncl: int, i: int): void = read_cl_m(airlock_nat(MAX_REC_FUEL), src, n, st, tab, ncl, i)

extern fun fill_rep_exh(tab: !Buf, i: int, nlen: int, rep: int, v: int, k: int): int = "mac#anth_die_int"

fun fill_rep_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), tab: !Buf, i: int, nlen: int, rep: int, v: int, k: int): int =
  if recfuel > 0 then (
    if ige(k, rep) then iadd(i, rep)
    else if ige(iadd(i, k), nlen) then ~1
    else let
      val () = buf_set32(tab, iadd(LN, iadd(i, k)), v)
    in
      fill_rep_m(recfuel - 1, tab, i, nlen, rep, v, iadd(k, 1))
    end
  ) else fill_rep_exh(tab, i, nlen, rep, v, k)

fun fill_rep(tab: !Buf, i: int, nlen: int, rep: int, v: int, k: int): int = fill_rep_m(airlock_nat(MAX_REC_FUEL), tab, i, nlen, rep, v, k)

datatype LenSym = LenBad | LenDirect | LenCopy | LenZero3 | LenZero11

fun len_sym(s: int): LenSym =
  if ilt(s, 0) then LenBad()
  else if ile(s, 15) then LenDirect()
  else if ieq(s, 16) then LenCopy()
  else if ieq(s, 17) then LenZero3()
  else if ieq(s, 18) then LenZero11()
  else LenBad()

extern fun read_lens_exh(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, nlen: int, i: int, prev: int): int = "mac#anth_die_int"
extern fun read_lens_code_exh(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, nlen: int, i: int, prev: int, s: int): int = "mac#anth_die_int"
extern fun read_rep_exh(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, nlen: int, i: int, rep: int, v: int): int = "mac#anth_die_int"

fun read_lens_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _, tab: !Buf, nlen: int, i: int, prev: int): int =
  if recfuel > 0 then (
    if ige(i, nlen) then 1
    else if is_on(st.err) then 0
    else let
      val s = hdec(src, n, st, tab, CC, CS)
    in
      case+ len_sym(s) of
      | LenBad() => 0
      | LenDirect() => let
          val () = buf_set32(tab, iadd(LN, i), s)
        in
          read_lens_m(recfuel - 1, src, n, st, tab, nlen, iadd(i, 1), s)
        end
      | LenCopy() => read_lens_code(recfuel - 1, src, n, st, tab, nlen, i, prev, s)
      | LenZero3() => read_lens_code(recfuel - 1, src, n, st, tab, nlen, i, prev, s)
      | LenZero11() => read_lens_code(recfuel - 1, src, n, st, tab, nlen, i, prev, s)
    end
  ) else read_lens_exh(src, n, st, tab, nlen, i, prev)

and read_lens_code {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _, tab: !Buf, nlen: int, i: int, prev: int, s: int): int =
  if recfuel > 0 then (
    case+ len_sym(s) of
    | LenCopy() => let
        val rep = iadd(3, bits(src, n, st, 2))
      in
        read_rep(recfuel - 1, src, n, st, tab, nlen, i, rep, prev)
      end
    | LenZero3() => let
        val rep = iadd(3, bits(src, n, st, 3))
      in
        read_rep(recfuel - 1, src, n, st, tab, nlen, i, rep, 0)
      end
    | LenZero11() => let
        val rep = iadd(11, bits(src, n, st, 7))
      in
        read_rep(recfuel - 1, src, n, st, tab, nlen, i, rep, 0)
      end
    | LenDirect() => 0 | LenBad() => 0
  ) else read_lens_code_exh(src, n, st, tab, nlen, i, prev, s)

and read_rep {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _, tab: !Buf, nlen: int, i: int, rep: int, v: int): int =
  if recfuel > 0 then let
    val j = fill_rep(tab, i, nlen, rep, v, 0)
  in
    if ilt(j, 0) then 0 else read_lens_m(recfuel - 1, src, n, st, tab, nlen, j, v)
  end else read_rep_exh(src, n, st, tab, nlen, i, rep, v)

fun read_lens(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, nlen: int, i: int, prev: int): int = read_lens_m(airlock_nat(MAX_REC_FUEL), src, n, st, tab, nlen, i, prev)

fun decode_dyn(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, dst: &Buf >> _): int = let
  val hlit = iadd(bits(src, n, st, 5), 257)
  val hdist = iadd(bits(src, n, st, 5), 1)
  val hclen = iadd(bits(src, n, st, 4), 4)
  val () = bzero(tab, CLN, iadd(CLN, 19))
  val () = read_cl(src, n, st, tab, hclen, 0)
  val () = huff_build(tab, CLN, 19, CC, CS)
  val () = bzero(tab, LN, iadd(LN, 320))
  val ok = read_lens(src, n, st, tab, iadd(hlit, hdist), 0, 0)
  val () = huff_build(tab, LN, hlit, LC, LS)
  val () = huff_build(tab, iadd(LN, hlit), hdist, DC, DS)
in
  if ieq(ok, 0) then 0 else symloop(src, n, st, tab, dst)
end

fun decode_fixed(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, dst: &Buf >> _): int = let
  val () = set_fixed(tab, 0)
  val () = set_dist5(tab, 0)
  val () = huff_build(tab, LN, 288, LC, LS)
  val () = huff_build(tab, iadd(LN, 288), 32, DC, DS)
in
  symloop(src, n, st, tab, dst)
end

fun u16(src: !Buf, i: int): int = iadd(buf_get(src, i), ishl(buf_get(src, iadd(i, 1)), 8))

extern fun stored_cp_exh(src: !Buf, dst: &Buf >> _, at: int, ln: int, i: int): void = "mac#anth_die_void"

fun stored_cp_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, dst: &Buf >> _, at: int, ln: int, i: int): void =
  if recfuel > 0 then (
    if ige(i, ln) then ()
    else let
      val () = buf_push(dst, buf_get(src, iadd(at, i)))
    in
      stored_cp_m(recfuel - 1, src, dst, at, ln, iadd(i, 1))
    end
  ) else stored_cp_exh(src, dst, at, ln, i)

fun stored_cp(src: !Buf, dst: &Buf >> _, at: int, ln: int, i: int): void = stored_cp_m(airlock_nat(MAX_REC_FUEL), src, dst, at, ln, i)

fun decode_stored(src: !Buf, n: int, st: &BitS >> _, dst: &Buf >> _): int = let
  val () = bitalign(st)
  val ln = u16(src, st.p)
  val nlen = u16(src, iadd(st.p, 2))
in
  if ine(iand(iadd(ln, nlen), 65535), 65535) then 0
  else if igt(iadd(st.p, iadd(ln, 4)), n) then 0
  else let
    val () = stored_cp(src, dst, iadd(st.p, 4), ln, 0)
    val () = st.p := iadd(st.p, iadd(ln, 4))
  in
    1
  end
end

datatype DeflateBlock = BlkStored | BlkFixed | BlkDyn | BlkBad

fun block_of(n: int): DeflateBlock =
  if ieq(n, 0) then BlkStored()
  else if ieq(n, 1) then BlkFixed()
  else if ieq(n, 2) then BlkDyn()
  else BlkBad()

extern fun blocks_exh(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, dst: &Buf >> _): int = "mac#anth_die_int"

fun blocks_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _, tab: !Buf, dst: &Buf >> _): int =
  if recfuel > 0 then (
    if is_on(st.err) then 0
    else let
      val fin = bit1(src, n, st)
      val ty = block_of(bits(src, n, st, 2))
      val ok = case+ ty of
        | BlkStored() => decode_stored(src, n, st, dst)
        | BlkFixed() => decode_fixed(src, n, st, tab, dst)
        | BlkDyn() => decode_dyn(src, n, st, tab, dst)
        | BlkBad() => 0
    in
      if ieq(ok, 0) then 0
      else if ieq(fin, 1) then 1
      else blocks_m(recfuel - 1, src, n, st, tab, dst)
    end
  ) else blocks_exh(src, n, st, tab, dst)

fun blocks(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, dst: &Buf >> _): int = blocks_m(airlock_nat(MAX_REC_FUEL), src, n, st, tab, dst)

fun inflate(src: !Buf, n: int, dst: &Buf >> _): int = let
  val cmf = buf_get(src, 0)
  val flg = buf_get(src, 1)
  val tab = buf_make(16384)
  var st: BitS = @{p= 2, nb= 0, acc= 0, err= Off}
  val () = if iand(flg, 32) <> 0 then st.p := iadd(st.p, 4) else ()
  val ok = if ine(iand(cmf, 15), 8) then 0 else blocks(src, n, st, tab, dst)
  val () = buf_free(tab)
in
  ok
end

fun be32(src: !Buf, i: int): int =
  iadd(ishl(buf_get(src, i), 24), iadd(ishl(buf_get(src, iadd(i, 1)), 16), iadd(ishl(buf_get(src, iadd(i, 2)), 8), buf_get(src, iadd(i, 3)))))

fun four(src: !Buf, i: int, a: int, b: int, c: int, d: int): bool =
  ieq(buf_get(src, i), a) andalso ieq(buf_get(src, iadd(i, 1)), b) andalso ieq(buf_get(src, iadd(i, 2)), c) andalso ieq(buf_get(src, iadd(i, 3)), d)

fun paeth(a: int, b: int, c: int): int = let
  val p = isub(iadd(a, b), c)
  val pa = iabs(isub(p, a))
  val pb = iabs(isub(p, b))
  val pc = iabs(isub(p, c))
in
  if ile(pa, pb) andalso ile(pa, pc) then a else if ile(pb, pc) then b else c
end

fun out_at(raw: !Buf, stride: int, x: int, y: int): int =
  if ilt(x, 0) orelse ilt(y, 0) then 0 else buf_get(raw, iadd(imul(y, stride), x))

datatype PngFilt = FiltNone | FiltSub | FiltUp | FiltAvg | FiltPaeth

fun filt_of(n: int): PngFilt =
  if ieq(n, 1) then FiltSub()
  else if ieq(n, 2) then FiltUp()
  else if ieq(n, 3) then FiltAvg()
  else if ieq(n, 4) then FiltPaeth()
  else FiltNone()

fun pred_of(f: PngFilt, left: int, up: int, ul: int): int = case+ f of
  | FiltSub() => left
  | FiltUp() => up
  | FiltAvg() => idiv(iadd(left, up), 2)
  | FiltPaeth() => paeth(left, up, ul)
  | FiltNone() => 0

extern fun unfilter_row_exh(src: !Buf, raw: &Buf >> _, base: int, stride: int, bpp: int, y: int, f: PngFilt, x: int): void = "mac#anth_die_void"

fun unfilter_row_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, raw: &Buf >> _, base: int, stride: int, bpp: int, y: int, f: PngFilt, x: int): void =
  if recfuel > 0 then (
    if ige(x, stride) then ()
    else let
      val v = buf_get(src, iadd(base, x))
      val left = out_at(raw, stride, isub(x, bpp), y)
      val up = out_at(raw, stride, x, isub(y, 1))
      val ul = out_at(raw, stride, isub(x, bpp), isub(y, 1))
      val pred = pred_of(f, left, up, ul)
      val () = buf_set(raw, iadd(imul(y, stride), x), iand(iadd(v, pred), 255))
    in
      unfilter_row_m(recfuel - 1, src, raw, base, stride, bpp, y, f, iadd(x, 1))
    end
  ) else unfilter_row_exh(src, raw, base, stride, bpp, y, f, x)

fun unfilter_row(src: !Buf, raw: &Buf >> _, base: int, stride: int, bpp: int, y: int, f: int, x: int): void = unfilter_row_m(airlock_nat(MAX_REC_FUEL), src, raw, base, stride, bpp, y, filt_of(f), x)

extern fun unfilter_rows_exh(inf: !Buf, raw: &Buf >> _, stride: int, bpp: int, h: int, y: int, p: int): int = "mac#anth_die_int"

fun unfilter_rows_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), inf: !Buf, raw: &Buf >> _, stride: int, bpp: int, h: int, y: int, p: int): int =
  if recfuel > 0 then (
    if ige(y, h) then 1
    else if ige(p, buf_len(inf)) then 0
    else let
      val f = buf_get(inf, p)
      val () = unfilter_row(inf, raw, iadd(p, 1), stride, bpp, y, f, 0)
    in
      unfilter_rows_m(recfuel - 1, inf, raw, stride, bpp, h, iadd(y, 1), iadd(p, iadd(stride, 1)))
    end
  ) else unfilter_rows_exh(inf, raw, stride, bpp, h, y, p)

fun unfilter_rows(inf: !Buf, raw: &Buf >> _, stride: int, bpp: int, h: int, y: int, p: int): int = unfilter_rows_m(airlock_nat(MAX_REC_FUEL), inf, raw, stride, bpp, h, y, p)

fun unfilter(inf: !Buf, w: int, h: int, bpp: int, raw: &Buf >> _): int =
  unfilter_rows(inf, raw, imul(w, bpp), bpp, h, 0, 0)

fun put4(dst: &Buf >> _, r: int, g: int, b: int, a: int): void = let
  val () = buf_push(dst, r)
  val () = buf_push(dst, g)
  val () = buf_push(dst, b)
in
  buf_push(dst, a)
end

datatype PngColor = ColGray | ColRgb | ColGrayA | ColRgba | ColOther

fun color_of(n: int): PngColor =
  if ieq(n, 0) then ColGray()
  else if ieq(n, 2) then ColRgb()
  else if ieq(n, 4) then ColGrayA()
  else if ieq(n, 6) then ColRgba()
  else ColOther()

fun color_bpp(k: PngColor): int = case+ k of
  | ColGray() => 1
  | ColRgb() => 3
  | ColGrayA() => 2
  | ColRgba() => 4
  | ColOther() => 0

fun color_stride(k: PngColor, w: int): int = case+ k of
  | ColGray() => w
  | ColGrayA() => imul(w, 2)
  | ColRgb() => imul(w, 3)
  | ColRgba() => imul(w, 4)
  | ColOther() => imul(w, 4)

fun put_color(dst: &Buf >> _, raw: !Buf, k: PngColor, p: int): void = case+ k of
  | ColGray() => put4(dst, buf_get(raw, p), buf_get(raw, p), buf_get(raw, p), 255)
  | ColGrayA() => put4(dst, buf_get(raw, p), buf_get(raw, p), buf_get(raw, p), buf_get(raw, iadd(p, 1)))
  | ColRgb() => put4(dst, buf_get(raw, p), buf_get(raw, iadd(p, 1)), buf_get(raw, iadd(p, 2)), 255)
  | ColRgba() => put4(dst, buf_get(raw, p), buf_get(raw, iadd(p, 1)), buf_get(raw, iadd(p, 2)), buf_get(raw, iadd(p, 3)))
  | ColOther() => put4(dst, buf_get(raw, p), buf_get(raw, iadd(p, 1)), buf_get(raw, iadd(p, 2)), buf_get(raw, iadd(p, 3)))

extern fun expand_exh(raw: !Buf, dst: &Buf >> _, w: int, h: int, kind: PngColor, y: int, x: int): void = "mac#anth_die_void"

fun expand_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), raw: !Buf, dst: &Buf >> _, w: int, h: int, kind: PngColor, y: int, x: int): void =
  if recfuel > 0 then (
    if ige(y, h) then ()
    else if ige(x, w) then expand_m(recfuel - 1, raw, dst, w, h, kind, iadd(y, 1), 0)
    else let
      val stride = color_stride(kind, w)
      val bpp = idiv(stride, w)
      val p = iadd(imul(y, stride), imul(x, bpp))
      val () = put_color(dst, raw, kind, p)
    in
      expand_m(recfuel - 1, raw, dst, w, h, kind, y, iadd(x, 1))
    end
  ) else expand_exh(raw, dst, w, h, kind, y, x)

fun expand(raw: !Buf, dst: &Buf >> _, w: int, h: int, kind: int, y: int, x: int): void = expand_m(airlock_nat(MAX_REC_FUEL), raw, dst, w, h, color_of(kind), y, x)

fun seal(b: &Buf >> _): int = 0

fun inflate_or(src: !Buf, n: int, dst: &Buf >> _, go: Toggle): int =
  if is_on(go) then inflate(src, n, dst)
  else let
    val () = seen_buf(src)
  in
    seal(dst)
  end

fun unfilter_or(inf: !Buf, w: int, h: int, bpp: int, raw: &Buf >> _, go: Toggle): int =
  if is_on(go) then unfilter(inf, w, h, bpp, raw)
  else let
    val () = seen_buf(inf)
  in
    seal(raw)
  end

fun expand_or(raw: !Buf, dst: &Buf >> _, w: int, h: int, kind: int, go: Toggle): int =
  if is_on(go) then let
    val () = expand(raw, dst, w, h, kind, 0, 0)
  in
    1
  end else let
    val () = seen_buf(raw)
  in
    seal(dst)
  end

fun png_copy(src: !Buf, idat: &Buf >> _, data: int, ln: int): void =
  buf_append_at(idat, src, data, ln)

fun png_ihdr(src: !Buf, data: int, w: &int >> _, h: &int >> _, kind: &int >> _, depth: &int >> _, inter: &int >> _): void = let
  val () = w := be32(src, data)
  val () = h := be32(src, iadd(data, 4))
  val () = depth := buf_get(src, iadd(data, 8))
  val () = kind := buf_get(src, iadd(data, 9))
  val () = inter := buf_get(src, iadd(data, 12))
in
end

datatype PngTag = TagBad | TagIhdr | TagIdat | TagIend | TagOther

fun tag_code(t: PngTag): int = case+ t of
  | TagBad() => 0
  | TagIhdr() => 1
  | TagIdat() => 2
  | TagIend() => 3
  | TagOther() => 4

fun is_tag(a: PngTag, b: PngTag): bool = tag_code(a) = tag_code(b)

fun png_tag(src: !Buf, p: int, ln: int, data: int, nxt: int): PngTag =
  if ilt(nxt, data) orelse igt(nxt, buf_len(src)) then TagBad()
  else if four(src, iadd(p, 4), 73, 72, 68, 82) then TagIhdr()
  else if four(src, iadd(p, 4), 73, 68, 65, 84) then TagIdat()
  else if four(src, iadd(p, 4), 73, 69, 78, 68) then TagIend()
  else TagOther()

extern fun png_chunks_exh(src: !Buf, idat: &Buf >> _, p: int, w: &int >> _, h: &int >> _, kind: &int >> _, depth: &int >> _, inter: &int >> _): int = "mac#anth_die_int"

fun png_chunks_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, idat: &Buf >> _, p: int, w: &int >> _, h: &int >> _, kind: &int >> _, depth: &int >> _, inter: &int >> _): int =
  if recfuel > 0 then (
    if ige(iadd(p, 8), buf_len(src)) then 0
    else let
      val ln = be32(src, p)
      val data = iadd(p, 8)
      val nxt = iadd(data, iadd(ln, 4))
      val tag = png_tag(src, p, ln, data, nxt)
      val () = if is_tag(tag, TagIhdr) then png_ihdr(src, data, w, h, kind, depth, inter) else ()
      val () = if is_tag(tag, TagIdat) then png_copy(src, idat, data, ln) else ()
    in
      if is_tag(tag, TagBad) then 0
      else if is_tag(tag, TagIend) then 1
      else png_chunks_m(recfuel - 1, src, idat, nxt, w, h, kind, depth, inter)
    end
  ) else png_chunks_exh(src, idat, p, w, h, kind, depth, inter)

fun png_chunks(src: !Buf, idat: &Buf >> _, p: int, w: &int >> _, h: &int >> _, kind: &int >> _, depth: &int >> _, inter: &int >> _): bool = ieq(png_chunks_m(airlock_nat(MAX_REC_FUEL), src, idat, p, w, h, kind, depth, inter), 1)

fun png_bpp(kind: int): int = color_bpp(color_of(kind))

fun png_fit(w: int, h: int): bool =
  igt(w, 0) andalso igt(h, 0) andalso ile(w, 8192) andalso ile(h, 8192) andalso ile(imul(w, h), 1048576)

fun png_inflate(idat: !Buf, saw: Toggle, inf: &Buf >> _): bool = let
  val nlen = buf_len(idat)
  val goz = is_on(saw) andalso igt(nlen, 2)
in
  ieq(inflate_or(idat, nlen, inf, toggle_of(goz)), 1)
end

fun png_raw_init(w: int, h: int, kind: int): Buf = let
  val bpp = png_bpp(kind)
  var raw = buf_make(imax(16, imul(imul(w, bpp), h)))
  val () = buf_set_len(raw, imul(imul(w, imax(bpp, 1)), h))
  val rcap = buf_cap(raw)
  val () = bzero(raw, 0, idiv(rcap, 4))
in
  raw
end

fun png_unfilter(inf: !Buf, raw: &Buf >> _, w: int, h: int, kind: int, depth: int, inter: Toggle, okz: Toggle): bool = let
  val bpp = png_bpp(kind)
  val fit = png_fit(w, h)
  val gou = is_on(okz) andalso fit andalso ieq(depth, 8) andalso is_off(inter) andalso igt(bpp, 0)
in
  ieq(unfilter_or(inf, w, h, bpp, raw, toggle_of(gou)), 1)
end

fun png_expand_buf(raw: !Buf, w: int, h: int, kind: int, oku: Toggle): Buf = let
  var dst = buf_make(imax(16, imul(imul(w, h), 4)))
  val () = seen_int(expand_or(raw, dst, w, h, kind, oku))
in
  dst
end

fun png_store_dims(oku: Toggle, w: int, h: int, wout: &int >> _, hout: &int >> _): void = let
  val wo = if is_on(oku) then w else 0
  val ho = if is_on(oku) then h else 0
  val () = wout := wo
  val () = hout := ho
in
end

fun png_result(dst: Buf, oku: Toggle): Buf =
  if is_on(oku) then dst else let
    val () = buf_free(dst)
  in
    buf_make(4)
  end

implement decode_png(src, wout, hout) = let
  var w: int = 0
  var h: int = 0
  var kind: int = ~1
  var depth: int = 0
  var inter: int = 0
  var idat = buf_make(64)
  val saw = png_chunks(src, idat, 8, w, h, kind, depth, inter)
  var inf = buf_make(64)
  val okz = png_inflate(idat, toggle_of(saw), inf)
  var raw = png_raw_init(w, h, kind)
  val oku = png_unfilter(inf, raw, w, h, kind, depth, toggle_of(ieq(inter, 1)), toggle_of(okz))
  var dst = png_expand_buf(raw, w, h, kind, toggle_of(oku))
  val () = png_store_dims(toggle_of(oku), w, h, wout, hout)
  val () = buf_free(idat)
  val () = buf_free(inf)
  val () = buf_free(raw)
in
  png_result(dst, toggle_of(oku))
end

fun png_byte(i: int): int =
  if ieq(i, 0) then 137 else if ieq(i, 1) then 80 else if ieq(i, 2) then 78 else if ieq(i, 3) then 71 else
  if ieq(i, 4) then 13 else if ieq(i, 5) then 10 else if ieq(i, 6) then 26 else if ieq(i, 7) then 10 else
  if ieq(i, 8) then 0 else if ieq(i, 9) then 0 else if ieq(i, 10) then 0 else if ieq(i, 11) then 13 else
  if ieq(i, 12) then 73 else if ieq(i, 13) then 72 else if ieq(i, 14) then 68 else if ieq(i, 15) then 82 else
  if ieq(i, 16) then 0 else if ieq(i, 17) then 0 else if ieq(i, 18) then 0 else if ieq(i, 19) then 1 else
  if ieq(i, 20) then 0 else if ieq(i, 21) then 0 else if ieq(i, 22) then 0 else if ieq(i, 23) then 1 else
  if ieq(i, 24) then 8 else if ieq(i, 25) then 2 else if ieq(i, 26) then 0 else if ieq(i, 27) then 0 else
  if ieq(i, 28) then 0 else if ieq(i, 29) then 144 else if ieq(i, 30) then 119 else if ieq(i, 31) then 83 else
  if ieq(i, 32) then 222 else if ieq(i, 33) then 0 else if ieq(i, 34) then 0 else if ieq(i, 35) then 0 else
  if ieq(i, 36) then 12 else if ieq(i, 37) then 73 else if ieq(i, 38) then 68 else if ieq(i, 39) then 65 else
  if ieq(i, 40) then 84 else if ieq(i, 41) then 120 else if ieq(i, 42) then 156 else if ieq(i, 43) then 99 else
  if ieq(i, 44) then 224 else if ieq(i, 45) then 18 else if ieq(i, 46) then 145 else if ieq(i, 47) then 3 else
  if ieq(i, 48) then 0 else if ieq(i, 49) then 0 else if ieq(i, 50) then 104 else if ieq(i, 51) then 0 else
  if ieq(i, 52) then 61 else if ieq(i, 53) then 84 else if ieq(i, 54) then 8 else if ieq(i, 55) then 163 else
  if ieq(i, 56) then 247 else if ieq(i, 57) then 0 else if ieq(i, 58) then 0 else if ieq(i, 59) then 0 else
  if ieq(i, 60) then 0 else if ieq(i, 61) then 73 else if ieq(i, 62) then 69 else if ieq(i, 63) then 78 else
  if ieq(i, 64) then 68 else if ieq(i, 65) then 174 else if ieq(i, 66) then 66 else if ieq(i, 67) then 96 else
  if ieq(i, 68) then 130 else
  0

extern fun push_png_exh(b: &Buf >> _, i: int): void = "mac#anth_die_void"

fun push_png_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: &Buf >> _, i: int): void =
  if recfuel > 0 then (
    if ige(i, 69) then ()
    else let
      val () = buf_push(b, png_byte(i))
    in
      push_png_m(recfuel - 1, b, iadd(i, 1))
    end
  ) else push_png_exh(b, i)

fun push_png(b: &Buf >> _, i: int): void = push_png_m(airlock_nat(MAX_REC_FUEL), b, i)

implement make_png() = let
  var pb = buf_make(80)
  val () = push_png(pb, 0)
in
  pb
end
