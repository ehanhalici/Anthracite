fun put_color(dst: &Buf >> _, raw: !Buf, k: PngColor, p: int): void = case+ k of
  | ColGray() => append_rgba_pixel(dst, buf_get(raw, p), buf_get(raw, p), buf_get(raw, p), 255)
  | ColGrayA() => append_rgba_pixel(dst, buf_get(raw, p), buf_get(raw, p), buf_get(raw, p), buf_get(raw, iadd(p, 1)))
  | ColRgb() => append_rgba_pixel(dst, buf_get(raw, p), buf_get(raw, iadd(p, 1)), buf_get(raw, iadd(p, 2)), 255)
  | ColRgba() => append_rgba_pixel(dst, buf_get(raw, p), buf_get(raw, iadd(p, 1)), buf_get(raw, iadd(p, 2)), buf_get(raw, iadd(p, 3)))
  | ColOther() => append_rgba_pixel(dst, buf_get(raw, p), buf_get(raw, iadd(p, 1)), buf_get(raw, iadd(p, 2)), buf_get(raw, iadd(p, 3)))

extern fun expand_fuel_exhausted(raw: !Buf, dst: &Buf >> _, w: int, h: int, kind: PngColor, y: int, x: int): void = "mac#anth_die_void"

fun expand_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), raw: !Buf, dst: &Buf >> _, w: int, h: int, kind: PngColor, y: int, x: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(y, h) then ()
    else if ige(x, w) then expand_with_fuel(recfuel - 1, raw, dst, w, h, kind, iadd(y, 1), 0)
    else let
      val stride = color_stride(kind, w)
      val bpp = idiv(stride, w)
      val p = iadd(imul(y, stride), imul(x, bpp))
      val () = put_color(dst, raw, kind, p)
    in
      expand_with_fuel(recfuel - 1, raw, dst, w, h, kind, y, iadd(x, 1))
    end
  ) else expand_fuel_exhausted(raw, dst, w, h, kind, y, x)

fun expand(raw: !Buf, dst: &Buf >> _, w: int, h: int, kind: int, y: int, x: int): void = expand_with_fuel(airlock_nat(MAX_REC_FUEL), raw, dst, w, h, color_of(kind), y, x)

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

extern fun png_chunks_fuel_exhausted(src: !Buf, idat: &Buf >> _, p: int, w: &int >> _, h: &int >> _, kind: &int >> _, depth: &int >> _, inter: &int >> _): int = "mac#anth_die_int"

fun png_chunks_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, idat: &Buf >> _, p: int, w: &int >> _, h: &int >> _, kind: &int >> _, depth: &int >> _, inter: &int >> _): int =
  if recursion_fuel_available(recfuel) then (
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
      else png_chunks_with_fuel(recfuel - 1, src, idat, nxt, w, h, kind, depth, inter)
    end
  ) else png_chunks_fuel_exhausted(src, idat, p, w, h, kind, depth, inter)

fun png_chunks(src: !Buf, idat: &Buf >> _, p: int, w: &int >> _, h: &int >> _, kind: &int >> _, depth: &int >> _, inter: &int >> _): bool = ieq(png_chunks_with_fuel(airlock_nat(MAX_REC_FUEL), src, idat, p, w, h, kind, depth, inter), 1)

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
  val () = zero_buffer_range(raw, 0, idiv(rcap, 4))
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
    buf_make(PNG_RESULT_BUFFER_INITIAL_BYTES)
  end

implement decode_png(src, wout, hout) = let
  var w: int = 0
  var h: int = 0
  var kind: int = ~1
  var depth: int = 0
  var inter: int = 0
  var idat = buf_make(DECODE_PNG_IDAT_INITIAL_BYTES)
  val saw = png_chunks(src, idat, 8, w, h, kind, depth, inter)
  var inf = buf_make(DECODE_PNG_INF_INITIAL_BYTES)
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

extern fun push_png_fuel_exhausted(b: &Buf >> _, i: int): void = "mac#anth_die_void"
