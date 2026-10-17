#ifndef ANTHRACITE_STB_JPG_HUFFMAN_HATS
#define ANTHRACITE_STB_JPG_HUFFMAN_HATS

macdef HUFF_TBL_WORDS = 1316
macdef HUFF_OFF_FAST = 0
macdef HUFF_OFF_CODE = 512
macdef HUFF_OFF_VALUES = 768
macdef HUFF_OFF_SIZE = 1024
macdef HUFF_OFF_MAXCODE = 1281
macdef HUFF_OFF_DELTA = 1299
macdef HUFF_BUF_WORDS = 5264 (* 4 tables * 1316 *)
macdef FAST_AC_BUF_WORDS = 2048 (* 4 tables * 512 *)

typedef JpgBits = @{
  code_buf= int,
  code_bits= int,
  marker= int,
  nomore= int,
  src_pos= int
}

fun huff_fast_get(hb: !Buf, t: int, c: int): int =
  buf_get32(hb, iadd(imul(iand(t, 3), HUFF_TBL_WORDS), iand(c, 511)))

fun huff_fast_set(hb: !Buf, t: int, c: int, v: int): void =
  buf_set32(hb, iadd(imul(iand(t, 3), HUFF_TBL_WORDS), iand(c, 511)), v)

fun huff_code_get(hb: !Buf, t: int, k: int): int =
  buf_get32(hb, iadd(iadd(imul(iand(t, 3), HUFF_TBL_WORDS), HUFF_OFF_CODE), iand(k, 255)))

fun huff_code_set(hb: !Buf, t: int, k: int, v: int): void =
  buf_set32(hb, iadd(iadd(imul(iand(t, 3), HUFF_TBL_WORDS), HUFF_OFF_CODE), iand(k, 255)), v)

fun huff_val_get(hb: !Buf, t: int, k: int): int =
  buf_get32(hb, iadd(iadd(imul(iand(t, 3), HUFF_TBL_WORDS), HUFF_OFF_VALUES), iand(k, 255)))

fun huff_val_set(hb: !Buf, t: int, k: int, v: int): void =
  buf_set32(hb, iadd(iadd(imul(iand(t, 3), HUFF_TBL_WORDS), HUFF_OFF_VALUES), iand(k, 255)), v)

fun huff_size_get(hb: !Buf, t: int, k: int): int =
  buf_get32(hb, iadd(iadd(imul(iand(t, 3), HUFF_TBL_WORDS), HUFF_OFF_SIZE), k))

fun huff_size_set(hb: !Buf, t: int, k: int, v: int): void =
  buf_set32(hb, iadd(iadd(imul(iand(t, 3), HUFF_TBL_WORDS), HUFF_OFF_SIZE), k), v)

fun huff_maxcode_get(hb: !Buf, t: int, j: int): int =
  buf_get32(hb, iadd(iadd(imul(iand(t, 3), HUFF_TBL_WORDS), HUFF_OFF_MAXCODE), j))

fun huff_maxcode_set(hb: !Buf, t: int, j: int, v: int): void =
  buf_set32(hb, iadd(iadd(imul(iand(t, 3), HUFF_TBL_WORDS), HUFF_OFF_MAXCODE), j), v)

fun huff_delta_get(hb: !Buf, t: int, j: int): int =
  buf_get32(hb, iadd(iadd(imul(iand(t, 3), HUFF_TBL_WORDS), HUFF_OFF_DELTA), j))

fun huff_delta_set(hb: !Buf, t: int, j: int, v: int): void =
  buf_set32(hb, iadd(iadd(imul(iand(t, 3), HUFF_TBL_WORDS), HUFF_OFF_DELTA), j), v)

fun fast_ac_get(fab: !Buf, t: int, c: int): int =
  buf_get32(fab, iadd(imul(iand(t, 3), 512), iand(c, 511)))

fun fast_ac_set(fab: !Buf, t: int, c: int, v: int): void =
  buf_set32(fab, iadd(imul(iand(t, 3), 512), iand(c, 511)), v)

fun bitstream_init(p0: int): JpgBits =
  @{code_buf= 0, code_bits= 0, marker= JPG_MARK_NONE, nomore= 0, src_pos= p0}

typedef MarkerRead = @{pos= int, mark= int}

fun read_escaped_marker {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, nsrc: int, pos: int): MarkerRead =
  if recursion_fuel_available(recfuel) then (
    if ige(pos, nsrc) then @{pos= pos, mark= JPG_MARK_NONE}
    else let
      val c = buf_get(src, pos)
      val p1 = iadd(pos, 1)
    in
      if ieq(c, 255) then read_escaped_marker(recfuel - 1, src, nsrc, p1)
      else @{pos= p1, mark= c}
    end
  ) else @{pos= pos, mark= JPG_MARK_NONE}

fun grow_buffer_escaped(src: !Buf, nsrc: int, bst: &JpgBits >> _): void = let
  val res = read_escaped_marker(airlock_nat(MAX_REC_FUEL), src, nsrc, bst.src_pos)
  val () = bst.src_pos := res.pos
in
  if ine(res.mark, 0) then let
    val () = bst.marker := res.mark and () = bst.nomore := 1
  in () end else let
    val () = bst.code_buf := ior(bst.code_buf, ishl(255, isub(24, bst.code_bits)))
    val () = bst.code_bits := iadd(bst.code_bits, 8)
  in () end
end

fun grow_buffer_byte(src: !Buf, nsrc: int, bst: &JpgBits >> _): void =
  if bst.nomore <> 0 then ()
  else if ige(bst.src_pos, nsrc) then bst.nomore := 1
  else let
    val b0 = buf_get(src, bst.src_pos)
    val () = bst.src_pos := iadd(bst.src_pos, 1)
  in
    if ine(b0, 255) then let
      val () = bst.code_buf := ior(bst.code_buf, ishl(b0, isub(24, bst.code_bits)))
      val () = bst.code_bits := iadd(bst.code_bits, 8)
    in () end else grow_buffer_escaped(src, nsrc, bst)
  end

fun grow_buffer_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, nsrc: int, bst: &JpgBits >> _): void =
  if recursion_fuel_available(recfuel) then (
    if bst.code_bits <= 24 andalso bst.nomore = 0 then let
      val () = grow_buffer_byte(src, nsrc, bst)
    in
      grow_buffer_loop(recfuel - 1, src, nsrc, bst)
    end else ()
  ) else ()

fun grow_buffer(src: !Buf, nsrc: int, bst: &JpgBits >> _): void =
  grow_buffer_loop(airlock_nat(MAX_REC_FUEL), src, nsrc, bst)

fun extend_receive(src: !Buf, nsrc: int, bst: &JpgBits >> _, n: int): int = let
  val () = if bst.code_bits < n then grow_buffer(src, nsrc, bst) else ()
in
  if bst.code_bits < n then 0
  else let
    val sgn = iand(ishr(bst.code_buf, 31), 1)
    val k = iand(ishr(bst.code_buf, isub(32, n)), bmask(n))
    val () = bst.code_buf := ishl(bst.code_buf, n)
    val () = bst.code_bits := isub(bst.code_bits, n)
  in
    if ieq(sgn, 1) then k else iadd(k, jbias(n))
  end
end

fun get_bits(src: !Buf, nsrc: int, bst: &JpgBits >> _, n: int): int = let
  val () = if bst.code_bits < n then grow_buffer(src, nsrc, bst) else ()
in
  if bst.code_bits < n then 0
  else let
    val k = iand(ishr(bst.code_buf, isub(32, n)), bmask(n))
    val () = bst.code_buf := ishl(bst.code_buf, n)
    val () = bst.code_bits := isub(bst.code_bits, n)
  in
    k
  end
end

fun get_bit(src: !Buf, nsrc: int, bst: &JpgBits >> _): int = let
  val () = if bst.code_bits < 1 then grow_buffer(src, nsrc, bst) else ()
in
  if bst.code_bits < 1 then 0
  else let
    val k = iand(ishr(bst.code_buf, 31), 1)
    val () = bst.code_buf := ishl(bst.code_buf, 1)
    val () = bst.code_bits := isub(bst.code_bits, 1)
  in
    k
  end
end

fun huff_slow_step {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), hb: !Buf, t: int, temp: int, k: int): int =
  if recursion_fuel_available(recfuel) then (
    if ige(k, 17) then 17
    else if ilt(temp, huff_maxcode_get(hb, t, k)) then k
    else huff_slow_step(recfuel - 1, hb, t, temp, iadd(k, 1))
  ) else 17

fun huff_decode_slow(hb: !Buf, t: int, bst: &JpgBits >> _): int = let
  val temp = iand(ishr(bst.code_buf, 16), 65535)
  val k = huff_slow_step(airlock_nat(MAX_REC_FUEL), hb, t, temp, 10)
in
  if ieq(k, 17) orelse igt(k, bst.code_bits) then ~1
  else let
    val c = iadd(iand(ishr(bst.code_buf, isub(32, k)), bmask(k)), huff_delta_get(hb, t, k))
  in
    if ilt(c, 0) orelse ige(c, 256) then ~1
    else let
      val () = bst.code_bits := isub(bst.code_bits, k)
      val () = bst.code_buf := ishl(bst.code_buf, k)
    in
      huff_val_get(hb, t, c)
    end
  end
end

fun huff_decode(src: !Buf, nsrc: int, hb: !Buf, t: int, bst: &JpgBits >> _): int = let
  val () = if bst.code_bits < 16 then grow_buffer(src, nsrc, bst) else ()
  val c = iand(ishr(bst.code_buf, 23), 511)
  val k = huff_fast_get(hb, t, c)
in
  if ilt(k, 255) then let
    val s = huff_size_get(hb, t, k)
  in
    if igt(s, bst.code_bits) then ~1
    else let
      val () = bst.code_buf := ishl(bst.code_buf, s)
      val () = bst.code_bits := isub(bst.code_bits, s)
    in
      huff_val_get(hb, t, k)
    end
  end else huff_decode_slow(hb, t, bst)
end

fun fill_size_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), hb: !Buf, t: int, sz: int, count: int, k: int): int =
  if recursion_fuel_available(recfuel) then (
    if ile(count, 0) then k
    else let
      val () = huff_size_set(hb, t, k, sz)
    in
      fill_size_loop(recfuel - 1, hb, t, sz, isub(count, 1), iadd(k, 1))
    end
  ) else k

fun build_huff_sizes {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), hb: !Buf, t: int, src: !Buf, soff: int, i: int, k: int): int =
  if recursion_fuel_available(recfuel) then (
    if ige(i, 16) then let
      val () = huff_size_set(hb, t, k, 0)
    in k end
    else let
      val cnt = buf_get(src, iadd(soff, i))
      val k2 = fill_size_loop(airlock_nat(MAX_REC_FUEL), hb, t, iadd(i, 1), cnt, k)
    in
      build_huff_sizes(recfuel - 1, hb, t, src, soff, iadd(i, 1), k2)
    end
  ) else k

typedef CodeState = @{code= int, k= int}

fun build_codes_inner {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), hb: !Buf, t: int, j: int, code: int, k: int): CodeState =
  if recursion_fuel_available(recfuel) then (
    if ieq(huff_size_get(hb, t, k), j) then let
      val () = huff_code_set(hb, t, k, code)
    in
      build_codes_inner(recfuel - 1, hb, t, j, iadd(code, 1), iadd(k, 1))
    end else @{code= code, k= k}
  ) else @{code= code, k= k}

fun build_huff_codes {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), hb: !Buf, t: int, j: int, code: int, k: int): void =
  if recursion_fuel_available(recfuel) then (
    if igt(j, 16) then huff_maxcode_set(hb, t, 17, 2147483647)
    else let
      val () = huff_delta_set(hb, t, j, isub(k, code))
      val res = build_codes_inner(airlock_nat(MAX_REC_FUEL), hb, t, j, code, k)
      val () = huff_maxcode_set(hb, t, j, ishl(res.code, isub(16, j)))
    in
      build_huff_codes(recfuel - 1, hb, t, iadd(j, 1), ishl(res.code, 1), res.k)
    end
  ) else ()

fun fill_fast_entries {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), hb: !Buf, t: int, sym: int, base: int, count: int, j: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(j, count) then ()
    else let
      val () = huff_fast_set(hb, t, iadd(base, j), sym)
    in
      fill_fast_entries(recfuel - 1, hb, t, sym, base, count, iadd(j, 1))
    end
  ) else ()

fun init_fast_table {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), hb: !Buf, t: int, i: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(i, 512) then ()
    else let
      val () = huff_fast_set(hb, t, i, 255)
    in
      init_fast_table(recfuel - 1, hb, t, iadd(i, 1))
    end
  ) else ()

fun build_fast_huff {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), hb: !Buf, t: int, nsymbols: int, i: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(i, nsymbols) then ()
    else let
      val s = huff_size_get(hb, t, i)
    in
      if ile(s, 9) andalso igt(s, 0) then let
        val c = ishl(huff_code_get(hb, t, i), isub(9, s))
        val m = ishl(1, isub(9, s))
        val () = fill_fast_entries(airlock_nat(MAX_REC_FUEL), hb, t, i, c, m, 0)
      in
        build_fast_huff(recfuel - 1, hb, t, nsymbols, iadd(i, 1))
      end else build_fast_huff(recfuel - 1, hb, t, nsymbols, iadd(i, 1))
    end
  ) else ()

fun build_huffman_table(hb: !Buf, t: int, src: !Buf, soff: int): int = let
  val nsymbols = build_huff_sizes(airlock_nat(MAX_REC_FUEL), hb, t, src, soff, 0, 0)
  val () = build_huff_codes(airlock_nat(MAX_REC_FUEL), hb, t, 1, 0, 0)
  val () = init_fast_table(airlock_nat(MAX_REC_FUEL), hb, t, 0)
  val () = build_fast_huff(airlock_nat(MAX_REC_FUEL), hb, t, nsymbols, 0)
in
  nsymbols
end

fun pack_fast_ac_entry(i: int, run: int, magbits: int, len: int): int = let
  val k0 = ishr(iand(ishl(i, len), 511), isub(9, magbits))
  val m = ishl(1, isub(magbits, 1))
  val k1 = if ilt(k0, m) then iadd(k0, iadd(ishl(~1, magbits), 1)) else k0
in
  if ige(k1, ~128) andalso ile(k1, 127) then
    iadd(imul(k1, 256), iadd(imul(run, 16), iadd(len, magbits)))
  else 0
end

fun fast_ac_one(fab: !Buf, hb: !Buf, t: int, i: int): void = let
  val fast = huff_fast_get(hb, t, i)
  val () = fast_ac_set(fab, t, i, 0)
in
  if ilt(fast, 255) then let
    val rs = huff_val_get(hb, t, fast)
    val run = iand(ishr(rs, 4), 15)
    val magbits = iand(rs, 15)
    val len = huff_size_get(hb, t, fast)
  in
    if igt(magbits, 0) andalso ile(iadd(len, magbits), 9) then let
      val p = pack_fast_ac_entry(i, run, magbits, len)
    in
      if ine(p, 0) then fast_ac_set(fab, t, i, p) else ()
    end else ()
  end else ()
end

fun build_fast_ac_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), fab: !Buf, hb: !Buf, t: int, i: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(i, 512) then ()
    else let
      val () = fast_ac_one(fab, hb, t, i)
    in
      build_fast_ac_loop(recfuel - 1, fab, hb, t, iadd(i, 1))
    end
  ) else ()

fun build_fast_ac(fab: !Buf, hb: !Buf, t: int): void =
  build_fast_ac_loop(airlock_nat(MAX_REC_FUEL), fab, hb, t, 0)

#endif
