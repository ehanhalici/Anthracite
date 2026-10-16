fun dbase0(e: int): int = dbase0_with_fuel(airlock_nat(MAX_REC_FUEL), e)

fun dist_of(src: !Buf, n: int, st: &BitS >> _, c: int): int =
  if ilt(c, 4) then iadd(c, 1)
  else let
    val e = dextra(c)
    val g = isub(c, iadd(2, imul(e, 2)))
    val extra = read_bits(src, n, st, e)
  in
    iadd(iadd(dbase0(e), imul(g, ishl(1, e))), extra)
  end

extern fun copy_out_fuel_exhausted(dst: &Buf >> _, dist: int, len: int, i: int): void = "mac#anth_die_void"

fun copy_out_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dst: &Buf >> _, dist: int, len: int, i: int): void =
  if recfuel > 0 then (
    if ige(i, len) then ()
    else let
      val n0 = buf_len(dst)
      val by = buf_get(dst, isub(n0, dist))
      val () = buf_push(dst, by)
    in
      copy_out_with_fuel(recfuel - 1, dst, dist, len, iadd(i, 1))
    end
  ) else copy_out_fuel_exhausted(dst, dist, len, i)

fun copy_out(dst: &Buf >> _, dist: int, len: int, i: int): void = copy_out_with_fuel(airlock_nat(MAX_REC_FUEL), dst, dist, len, i)

datatype DeflateSym = SymBad | SymEnd | SymLit | SymLen

fun sym_kind(s: int): DeflateSym =
  if ilt(s, 0) then SymBad()
  else if ieq(s, 256) then SymEnd()
  else if ilt(s, 256) then SymLit()
  else SymLen()

extern fun symloop_fuel_exhausted(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, dst: &Buf >> _): int = "mac#anth_die_int"

fun symloop_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _, tab: !Buf, dst: &Buf >> _): int =
  if recfuel > 0 then (
    if igt(buf_len(dst), 16000000) orelse is_on(st.err) then 0
    else let
      val s = decode_huffman_symbol(src, n, st, tab, LC, LS)
      val k = sym_kind(s)
    in
      case+ k of
      | SymBad() => 0
      | SymEnd() => 1
      | SymLit() => let
          val () = buf_push(dst, s)
        in
          symloop_with_fuel(recfuel - 1, src, n, st, tab, dst)
        end
      | SymLen() => sym_copy(recfuel - 1, src, n, st, tab, dst, s)
    end
  ) else symloop_fuel_exhausted(src, n, st, tab, dst)

and sym_copy {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _, tab: !Buf, dst: &Buf >> _, s: int): int =
  if recfuel > 0 then let
    val ln = length_of(src, n, st, s)
    val dc = decode_huffman_symbol(src, n, st, tab, DC, DS)
    val dist = dist_of(src, n, st, dc)
  in
    if ile(dist, 0) orelse igt(dist, buf_len(dst)) then 0
    else let
      val () = copy_out(dst, dist, ln, 0)
    in
      symloop_with_fuel(recfuel - 1, src, n, st, tab, dst)
    end
  end else 0

fun symloop(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, dst: &Buf >> _): int = symloop_with_fuel(airlock_nat(MAX_REC_FUEL), src, n, st, tab, dst)

extern fun set_fixed_fuel_exhausted(tab: !Buf, i: int): void = "mac#anth_die_void"

fun set_fixed_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), tab: !Buf, i: int): void =
  if recfuel > 0 then (
    if ige(i, 288) then ()
    else let
      val L = if ilt(i, 144) then 8 else if ilt(i, 256) then 9 else if ilt(i, 280) then 7 else 8
      val () = buf_set32(tab, iadd(LN, i), L)
    in
      set_fixed_with_fuel(recfuel - 1, tab, iadd(i, 1))
    end
  ) else set_fixed_fuel_exhausted(tab, i)

fun set_fixed(tab: !Buf, i: int): void = set_fixed_with_fuel(airlock_nat(MAX_REC_FUEL), tab, i)

extern fun set_dist5_fuel_exhausted(tab: !Buf, i: int): void = "mac#anth_die_void"

fun set_dist5_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), tab: !Buf, i: int): void =
  if recfuel > 0 then (
    if ige(i, 32) then ()
    else let
      val () = buf_set32(tab, iadd(iadd(LN, 288), i), 5)
    in
      set_dist5_with_fuel(recfuel - 1, tab, iadd(i, 1))
    end
  ) else set_dist5_fuel_exhausted(tab, i)

fun set_dist5(tab: !Buf, i: int): void = set_dist5_with_fuel(airlock_nat(MAX_REC_FUEL), tab, i)

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

extern fun read_cl_fuel_exhausted(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, ncl: int, i: int): void = "mac#anth_die_void"

fun read_cl_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _, tab: !Buf, ncl: int, i: int): void =
  if recfuel > 0 then (
    if ige(i, ncl) then ()
    else let
      val () = buf_set32(tab, iadd(CLN, cl_order(i)), read_bits(src, n, st, 3))
    in
      read_cl_with_fuel(recfuel - 1, src, n, st, tab, ncl, iadd(i, 1))
    end
  ) else read_cl_fuel_exhausted(src, n, st, tab, ncl, i)

fun read_cl(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, ncl: int, i: int): void = read_cl_with_fuel(airlock_nat(MAX_REC_FUEL), src, n, st, tab, ncl, i)

extern fun fill_rep_fuel_exhausted(tab: !Buf, i: int, nlen: int, rep: int, v: int, k: int): int = "mac#anth_die_int"

fun fill_rep_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), tab: !Buf, i: int, nlen: int, rep: int, v: int, k: int): int =
  if recfuel > 0 then (
    if ige(k, rep) then iadd(i, rep)
    else if ige(iadd(i, k), nlen) then ~1
    else let
      val () = buf_set32(tab, iadd(LN, iadd(i, k)), v)
    in
      fill_rep_with_fuel(recfuel - 1, tab, i, nlen, rep, v, iadd(k, 1))
    end
  ) else fill_rep_fuel_exhausted(tab, i, nlen, rep, v, k)

fun fill_rep(tab: !Buf, i: int, nlen: int, rep: int, v: int, k: int): int = fill_rep_with_fuel(airlock_nat(MAX_REC_FUEL), tab, i, nlen, rep, v, k)

datatype LenSym = LenBad | LenDirect | LenCopy | LenZero3 | LenZero11

fun len_sym(s: int): LenSym =
  if ilt(s, 0) then LenBad()
  else if ile(s, 15) then LenDirect()
  else if ieq(s, 16) then LenCopy()
  else if ieq(s, 17) then LenZero3()
  else if ieq(s, 18) then LenZero11()
  else LenBad()

extern fun read_lens_fuel_exhausted(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, nlen: int, i: int, prev: int): int = "mac#anth_die_int"
extern fun read_lens_code_fuel_exhausted(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, nlen: int, i: int, prev: int, s: int): int = "mac#anth_die_int"
extern fun read_rep_fuel_exhausted(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, nlen: int, i: int, rep: int, v: int): int = "mac#anth_die_int"

fun read_lens_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _, tab: !Buf, nlen: int, i: int, prev: int): int =
  if recfuel > 0 then (
    if ige(i, nlen) then 1
    else if is_on(st.err) then 0
    else let
      val s = decode_huffman_symbol(src, n, st, tab, CC, CS)
    in
      case+ len_sym(s) of
      | LenBad() => 0
      | LenDirect() => let
          val () = buf_set32(tab, iadd(LN, i), s)
        in
          read_lens_with_fuel(recfuel - 1, src, n, st, tab, nlen, iadd(i, 1), s)
        end
      | LenCopy() => read_lens_code(recfuel - 1, src, n, st, tab, nlen, i, prev, s)
      | LenZero3() => read_lens_code(recfuel - 1, src, n, st, tab, nlen, i, prev, s)
      | LenZero11() => read_lens_code(recfuel - 1, src, n, st, tab, nlen, i, prev, s)
    end
  ) else read_lens_fuel_exhausted(src, n, st, tab, nlen, i, prev)

and read_lens_code {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _, tab: !Buf, nlen: int, i: int, prev: int, s: int): int =
  if recfuel > 0 then (
    case+ len_sym(s) of
    | LenCopy() => let
        val rep = iadd(3, read_bits(src, n, st, 2))
      in
        read_rep(recfuel - 1, src, n, st, tab, nlen, i, rep, prev)
      end
    | LenZero3() => let
        val rep = iadd(3, read_bits(src, n, st, 3))
      in
        read_rep(recfuel - 1, src, n, st, tab, nlen, i, rep, 0)
      end
    | LenZero11() => let
        val rep = iadd(11, read_bits(src, n, st, 7))
      in
        read_rep(recfuel - 1, src, n, st, tab, nlen, i, rep, 0)
      end
    | LenDirect() => 0 | LenBad() => 0
  ) else read_lens_code_fuel_exhausted(src, n, st, tab, nlen, i, prev, s)

and read_rep {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _, tab: !Buf, nlen: int, i: int, rep: int, v: int): int =
  if recfuel > 0 then let
    val j = fill_rep(tab, i, nlen, rep, v, 0)
  in
    if ilt(j, 0) then 0 else read_lens_with_fuel(recfuel - 1, src, n, st, tab, nlen, j, v)
  end else read_rep_fuel_exhausted(src, n, st, tab, nlen, i, rep, v)

