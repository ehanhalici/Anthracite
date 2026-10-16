fun read_lens(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, nlen: int, i: int, prev: int): int = read_lens_with_fuel(airlock_nat(MAX_REC_FUEL), src, n, st, tab, nlen, i, prev)

fun decode_dyn(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, dst: &Buf >> _): int = let
  val hlit = iadd(read_bits(src, n, st, 5), 257)
  val hdist = iadd(read_bits(src, n, st, 5), 1)
  val hclen = iadd(read_bits(src, n, st, 4), 4)
  val () = zero_buffer_range(tab, CLN, iadd(CLN, 19))
  val () = read_cl(src, n, st, tab, hclen, 0)
  val () = huff_build(tab, CLN, 19, CC, CS)
  val () = zero_buffer_range(tab, LN, iadd(LN, 320))
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

extern fun stored_cp_fuel_exhausted(src: !Buf, dst: &Buf >> _, at: int, ln: int, i: int): void = "mac#anth_die_void"

fun stored_cp_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, dst: &Buf >> _, at: int, ln: int, i: int): void =
  if recfuel > 0 then (
    if ige(i, ln) then ()
    else let
      val () = buf_push(dst, buf_get(src, iadd(at, i)))
    in
      stored_cp_with_fuel(recfuel - 1, src, dst, at, ln, iadd(i, 1))
    end
  ) else stored_cp_fuel_exhausted(src, dst, at, ln, i)

fun stored_cp(src: !Buf, dst: &Buf >> _, at: int, ln: int, i: int): void = stored_cp_with_fuel(airlock_nat(MAX_REC_FUEL), src, dst, at, ln, i)

fun decode_stored(src: !Buf, n: int, st: &BitS >> _, dst: &Buf >> _): int = let
  val () = bitalign(st)
  val ln = u16(src, st.p)
  val nlen = u16(src, iadd(st.p, 2))
in
  if ine(iand(iadd(ln, nlen), WORD16_MAX_VALUE), WORD16_MAX_VALUE) then 0
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

extern fun blocks_fuel_exhausted(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, dst: &Buf >> _): int = "mac#anth_die_int"

fun blocks_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, n: int, st: &BitS >> _, tab: !Buf, dst: &Buf >> _): int =
  if recfuel > 0 then (
    if is_on(st.err) then 0
    else let
      val fin = read_one_bit(src, n, st)
      val ty = block_of(read_bits(src, n, st, 2))
      val ok = case+ ty of
        | BlkStored() => decode_stored(src, n, st, dst)
        | BlkFixed() => decode_fixed(src, n, st, tab, dst)
        | BlkDyn() => decode_dyn(src, n, st, tab, dst)
        | BlkBad() => 0
    in
      if ieq(ok, 0) then 0
      else if ieq(fin, 1) then 1
      else blocks_with_fuel(recfuel - 1, src, n, st, tab, dst)
    end
  ) else blocks_fuel_exhausted(src, n, st, tab, dst)

fun blocks(src: !Buf, n: int, st: &BitS >> _, tab: !Buf, dst: &Buf >> _): int = blocks_with_fuel(airlock_nat(MAX_REC_FUEL), src, n, st, tab, dst)

fun inflate(src: !Buf, n: int, dst: &Buf >> _): int = let
  val cmf = buf_get(src, 0)
  val flg = buf_get(src, 1)
  val tab = buf_make(INFLATE_TAB_INITIAL_BYTES)
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

extern fun unfilter_row_fuel_exhausted(src: !Buf, raw: &Buf >> _, base: int, stride: int, bpp: int, y: int, f: PngFilt, x: int): void = "mac#anth_die_void"

fun unfilter_row_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, raw: &Buf >> _, base: int, stride: int, bpp: int, y: int, f: PngFilt, x: int): void =
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
      unfilter_row_with_fuel(recfuel - 1, src, raw, base, stride, bpp, y, f, iadd(x, 1))
    end
  ) else unfilter_row_fuel_exhausted(src, raw, base, stride, bpp, y, f, x)

fun unfilter_row(src: !Buf, raw: &Buf >> _, base: int, stride: int, bpp: int, y: int, f: int, x: int): void = unfilter_row_with_fuel(airlock_nat(MAX_REC_FUEL), src, raw, base, stride, bpp, y, filt_of(f), x)

extern fun unfilter_rows_fuel_exhausted(inf: !Buf, raw: &Buf >> _, stride: int, bpp: int, h: int, y: int, p: int): int = "mac#anth_die_int"

fun unfilter_rows_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), inf: !Buf, raw: &Buf >> _, stride: int, bpp: int, h: int, y: int, p: int): int =
  if recfuel > 0 then (
    if ige(y, h) then 1
    else if ige(p, buf_len(inf)) then 0
    else let
      val f = buf_get(inf, p)
      val () = unfilter_row(inf, raw, iadd(p, 1), stride, bpp, y, f, 0)
    in
      unfilter_rows_with_fuel(recfuel - 1, inf, raw, stride, bpp, h, iadd(y, 1), iadd(p, iadd(stride, 1)))
    end
  ) else unfilter_rows_fuel_exhausted(inf, raw, stride, bpp, h, y, p)

fun unfilter_rows(inf: !Buf, raw: &Buf >> _, stride: int, bpp: int, h: int, y: int, p: int): int = unfilter_rows_with_fuel(airlock_nat(MAX_REC_FUEL), inf, raw, stride, bpp, h, y, p)

fun unfilter(inf: !Buf, w: int, h: int, bpp: int, raw: &Buf >> _): int =
  unfilter_rows(inf, raw, imul(w, bpp), bpp, h, 0, 0)

fun append_rgba_pixel(dst: &Buf >> _, r: int, g: int, b: int, a: int): void = let
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

