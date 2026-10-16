#ifndef ANTHRACITE_STB_JPG_MARKERS_HATS
#define ANTHRACITE_STB_JPG_MARKERS_HATS

macdef META_WIDTH = 0
macdef META_HEIGHT = 1
macdef META_NCOMP = 2
macdef META_PROGRESSIVE = 3
macdef META_HMAX = 4
macdef META_VMAX = 5
macdef META_MCU_X = 6
macdef META_MCU_Y = 7
macdef META_MCU_W = 8
macdef META_MCU_H = 9
macdef META_RESTART_INTERVAL = 10
macdef META_SCAN_N = 11
macdef META_SPEC_START = 12
macdef META_SPEC_END = 13
macdef META_SUCC_HIGH = 14
macdef META_SUCC_LOW = 15
macdef META_JFIF = 16
macdef META_APP14 = 17
macdef META_RGB = 18
macdef META_DECODED_COMPONENTS = 19
macdef META_HEADER_WORDS = 20

macdef COMP_STRIDE = 16
macdef COMP_ID = 0
macdef COMP_H = 1
macdef COMP_V = 2
macdef COMP_TQ = 3
macdef COMP_HD = 4
macdef COMP_HA = 5
macdef COMP_DC_PRED = 6
macdef COMP_X = 7
macdef COMP_Y = 8
macdef COMP_W2 = 9
macdef COMP_H2 = 10
macdef COMP_COEFF_W = 11
macdef COMP_COEFF_H = 12
macdef COMP_PLANE_OFF = 13
macdef COMP_COEFF_OFF = 14
macdef META_ORDER_BASE = 84

fun comp_get(meta: !Buf, c: int, fld: int): int =
  buf_get32(meta, iadd(iadd(META_HEADER_WORDS, imul(iand(c, 3), COMP_STRIDE)), fld))

fun comp_set(meta: !Buf, c: int, fld: int, v: int): void =
  buf_set32(meta, iadd(iadd(META_HEADER_WORDS, imul(iand(c, 3), COMP_STRIDE)), fld), v)

fun order_get(meta: !Buf, i: int): int =
  buf_get32(meta, iadd(META_ORDER_BASE, iand(i, 3)))

fun order_set(meta: !Buf, i: int, v: int): void =
  buf_set32(meta, iadd(META_ORDER_BASE, iand(i, 3)), v)

fun jpeg_is_jfif(src: !Buf, offset: int): bool =
  ieq(buf_get(src, offset), char2int0('J')) andalso
  ieq(buf_get(src, iadd(offset, 1)), char2int0('F')) andalso
  ieq(buf_get(src, iadd(offset, 2)), char2int0('I')) andalso
  ieq(buf_get(src, iadd(offset, 3)), char2int0('F')) andalso
  ieq(buf_get(src, iadd(offset, 4)), 0)

fun jpeg_is_adobe(src: !Buf, offset: int): bool =
  ieq(buf_get(src, offset), char2int0('A')) andalso
  ieq(buf_get(src, iadd(offset, 1)), char2int0('d')) andalso
  ieq(buf_get(src, iadd(offset, 2)), char2int0('o')) andalso
  ieq(buf_get(src, iadd(offset, 3)), char2int0('b')) andalso
  ieq(buf_get(src, iadd(offset, 4)), char2int0('e')) andalso
  ieq(buf_get(src, iadd(offset, 5)), 0)

fun parse_color_marker(src: !Buf, nsrc: int, bst: &JpgBits >> _, meta: !Buf, marker: int): bool = let
  val length_bytes = be16_at(src, bst.src_pos)
  val end_offset = iadd(bst.src_pos, length_bytes)
  val payload = iadd(bst.src_pos, WORD16_BYTES)
  val payload_bytes = isub(length_bytes, WORD16_BYTES)
in
  if ilt(length_bytes, WORD16_BYTES) orelse igt(end_offset, nsrc) then false
  else let
    val () = if ieq(marker, JPG_MARK_APP0) andalso ige(payload_bytes, JPG_JFIF_TAG_BYTES) andalso jpeg_is_jfif(src, payload)
      then buf_set32(meta, META_JFIF, 1) else ()
    val () = if ieq(marker, JPG_MARK_APP14) andalso ige(payload_bytes, JPG_ADOBE_PAYLOAD_BYTES) andalso jpeg_is_adobe(src, payload)
      then buf_set32(meta, META_APP14, buf_get(src, iadd(payload, JPG_ADOBE_TRANSFORM_OFFSET))) else ()
    val () = bst.src_pos := end_offset
  in true end
end

fun skip_ff_bytes {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, nsrc: int, pos: int): MarkerRead =
  if recursion_fuel_available(recfuel) then (
    if ige(pos, nsrc) then @{pos= pos, mark= JPG_MARK_NONE}
    else let
      val b = buf_get(src, pos)
      val p1 = iadd(pos, 1)
    in
      if ieq(b, 255) then skip_ff_bytes(recfuel - 1, src, nsrc, p1)
      else @{pos= p1, mark= b}
    end
  ) else @{pos= pos, mark= JPG_MARK_NONE}

fun get_marker(src: !Buf, nsrc: int, bst: &JpgBits >> _): int =
  if bst.marker <> JPG_MARK_NONE then let
    val m = bst.marker
    val () = bst.marker := JPG_MARK_NONE
  in m end
  else if ige(bst.src_pos, nsrc) then JPG_MARK_NONE
  else let
    val b = buf_get(src, bst.src_pos)
    val () = bst.src_pos := iadd(bst.src_pos, 1)
  in
    if ine(b, 255) then JPG_MARK_NONE
    else let
      val res = skip_ff_bytes(airlock_nat(MAX_REC_FUEL), src, nsrc, bst.src_pos)
      val () = bst.src_pos := res.pos
    in res.mark end
  end

fun parse_dqt_entries {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, p: int, dqt: !Buf, t: int, sixteen: int, i: int): int =
  if recursion_fuel_available(recfuel) then (
    if ige(i, 64) then p
    else let
      val zig = dezigzag(i)
      val v = if sixteen <> 0 then be16_at(src, p) else buf_get(src, p)
      val p_next = iadd(p, if sixteen <> 0 then 2 else 1)
      val () = dequant_set(dqt, t, zig, v)
    in
      parse_dqt_entries(recfuel - 1, src, p_next, dqt, t, sixteen, iadd(i, 1))
    end
  ) else p

fun parse_dqt_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, p: int, end_p: int, dqt: !Buf): bool =
  if recursion_fuel_available(recfuel) then (
    if ige(p, end_p) then true
    else let
      val q = buf_get(src, p)
      val sixteen = ishr(q, 4)
      val t = iand(q, 15)
      val p1 = iadd(p, 1)
    in
      if igt(t, 3) orelse (sixteen <> 0 andalso sixteen <> 1) then false
      else let
        val p2 = parse_dqt_entries(airlock_nat(MAX_REC_FUEL), src, p1, dqt, t, sixteen, 0)
      in
        parse_dqt_loop(recfuel - 1, src, p2, end_p, dqt)
      end
    end
  ) else false

fun parse_dqt(src: !Buf, nsrc: int, bst: &JpgBits >> _, dqt: !Buf): bool = let
  val len = be16_at(src, bst.src_pos)
  val end_p = iadd(bst.src_pos, len)
  val () = bst.src_pos := iadd(bst.src_pos, 2)
in
  if ilt(len, 2) orelse igt(end_p, nsrc) then false
  else let
    val ok = parse_dqt_loop(airlock_nat(MAX_REC_FUEL), src, bst.src_pos, end_p, dqt)
    val () = bst.src_pos := end_p
  in ok end
end

fun read_huff_values {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, p: int, hb: !Buf, t: int, nsymbols: int, i: int): int =
  if recursion_fuel_available(recfuel) then (
    if ige(i, nsymbols) then p
    else let
      val v = buf_get(src, p)
      val () = huff_val_set(hb, t, i, v)
    in
      read_huff_values(recfuel - 1, src, iadd(p, 1), hb, t, nsymbols, iadd(i, 1))
    end
  ) else p

fun parse_dht_one(src: !Buf, p1: int, tc: int, th: int, hdc: !Buf, hac: !Buf, fab: !Buf): int =
  if tc = 0 then let
    val nsymbols = build_huffman_table(hdc, th, src, p1)
    val p2 = iadd(p1, 16)
  in
    read_huff_values(airlock_nat(MAX_REC_FUEL), src, p2, hdc, th, nsymbols, 0)
  end else let
    val nsymbols = build_huffman_table(hac, th, src, p1)
    val p2 = iadd(p1, 16)
    val p3 = read_huff_values(airlock_nat(MAX_REC_FUEL), src, p2, hac, th, nsymbols, 0)
    val () = build_fast_ac(fab, hac, th)
  in
    p3
  end

fun parse_dht_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, p: int, end_p: int, hdc: !Buf, hac: !Buf, fab: !Buf): bool =
  if recursion_fuel_available(recfuel) then (
    if ige(p, end_p) then true
    else let
      val q = buf_get(src, p)
      val tc = ishr(q, 4)
      val th = iand(q, 15)
      val p1 = iadd(p, 1)
    in
      if igt(tc, 1) orelse igt(th, 3) then false
      else let
        val p3 = parse_dht_one(src, p1, tc, th, hdc, hac, fab)
      in
        parse_dht_loop(recfuel - 1, src, p3, end_p, hdc, hac, fab)
      end
    end
  ) else false

fun parse_dht(src: !Buf, nsrc: int, bst: &JpgBits >> _, hdc: !Buf, hac: !Buf, fab: !Buf): bool = let
  val len = be16_at(src, bst.src_pos)
  val end_p = iadd(bst.src_pos, len)
  val () = bst.src_pos := iadd(bst.src_pos, 2)
in
  if ilt(len, 2) orelse igt(end_p, nsrc) then false
  else let
    val ok = parse_dht_loop(airlock_nat(MAX_REC_FUEL), src, bst.src_pos, end_p, hdc, hac, fab)
    val () = bst.src_pos := end_p
  in ok end
end

fun parse_dri(src: !Buf, nsrc: int, bst: &JpgBits >> _, meta: !Buf): bool = let
  val len = be16_at(src, bst.src_pos)
in
  if ine(len, 4) orelse igt(iadd(bst.src_pos, 4), nsrc) then false
  else let
    val ri = be16_at(src, iadd(bst.src_pos, 2))
    val () = buf_set32(meta, META_RESTART_INTERVAL, ri)
    val () = bst.src_pos := iadd(bst.src_pos, 4)
  in true end
end

fun calc_mcu_info(meta: !Buf, w: int, h: int, h_max: int, v_max: int): void = let
  val mcu_w = imul(h_max, 8)
  val mcu_h = imul(v_max, 8)
  val mcu_x = idiv(iadd(iadd(w, mcu_w), ~1), mcu_w)
  val mcu_y = idiv(iadd(iadd(h, mcu_h), ~1), mcu_h)
  val () = buf_set32(meta, META_HMAX, h_max)
  val () = buf_set32(meta, META_VMAX, v_max)
  val () = buf_set32(meta, META_MCU_W, mcu_w)
  val () = buf_set32(meta, META_MCU_H, mcu_h)
  val () = buf_set32(meta, META_MCU_X, mcu_x)
  val () = buf_set32(meta, META_MCU_Y, mcu_y)
in () end

fun init_comp_dims(meta: !Buf, w: int, h: int, h_max: int, v_max: int, mcu_x: int, mcu_y: int, i: int): void = let
  val ch = comp_get(meta, i, COMP_H)
  val cv = comp_get(meta, i, COMP_V)
  val cx = idiv(iadd(imul(w, ch), isub(h_max, 1)), h_max)
  val cy = idiv(iadd(imul(h, cv), isub(v_max, 1)), v_max)
  val w2 = imul(imul(mcu_x, ch), 8)
  val h2 = imul(imul(mcu_y, cv), 8)
  val () = comp_set(meta, i, COMP_X, cx)
  val () = comp_set(meta, i, COMP_Y, cy)
  val () = comp_set(meta, i, COMP_W2, w2)
  val () = comp_set(meta, i, COMP_H2, h2)
  val () = comp_set(meta, i, COMP_COEFF_W, idiv(w2, 8))
  val () = comp_set(meta, i, COMP_COEFF_H, idiv(h2, 8))
in () end

fun check_subsampling {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), meta: !Buf, ncomp: int, h_max: int, v_max: int, i: int): bool =
  if recursion_fuel_available(recfuel) then (
    if ige(i, ncomp) then true
    else let
      val ch = comp_get(meta, i, COMP_H)
      val cv = comp_get(meta, i, COMP_V)
    in
      if ilt(ch, 1) orelse igt(ch, JPG_MAX_SAMPLE_FACTOR) orelse ilt(cv, 1) orelse igt(cv, JPG_MAX_SAMPLE_FACTOR)
         orelse imod(h_max, ch) <> 0 orelse imod(v_max, cv) <> 0
         orelse ige(comp_get(meta, i, COMP_TQ), JPG_MAX_TABLES) then false
      else check_subsampling(recfuel - 1, meta, ncomp, h_max, v_max, iadd(i, 1))
    end
  ) else false

fun setup_comps_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), meta: !Buf, ncomp: int, w: int, h: int, h_max: int, v_max: int, mx: int, my: int, i: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(i, ncomp) then ()
    else let
      val () = init_comp_dims(meta, w, h, h_max, v_max, mx, my, i)
    in
      setup_comps_loop(recfuel - 1, meta, ncomp, w, h, h_max, v_max, mx, my, iadd(i, 1))
    end
  ) else ()

typedef SofComps = @{p= int, h_max= int, v_max= int}

fun parse_sof_comps {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, p: int, meta: !Buf, ncomp: int, i: int, h_max: int, v_max: int): SofComps =
  if recursion_fuel_available(recfuel) then (
    if ige(i, ncomp) then @{p= p, h_max= h_max, v_max= v_max}
    else let
      val cid = buf_get(src, p)
      val q = buf_get(src, iadd(p, 1))
      val tq = buf_get(src, iadd(p, 2))
      val ch = ishr(q, 4)
      val cv = iand(q, 15)
      val () = comp_set(meta, i, COMP_ID, cid)
      val () = comp_set(meta, i, COMP_H, ch)
      val () = comp_set(meta, i, COMP_V, cv)
      val () = comp_set(meta, i, COMP_TQ, tq)
      val hm = if igt(ch, h_max) then ch else h_max
      val vm = if igt(cv, v_max) then cv else v_max
    in
      parse_sof_comps(recfuel - 1, src, iadd(p, 3), meta, ncomp, iadd(i, 1), hm, vm)
    end
  ) else @{p= p, h_max= h_max, v_max= v_max}

fun sof_setup_meta(meta: !Buf, w: int, h: int, c: int, res: SofComps): void = let
  val () = calc_mcu_info(meta, w, h, res.h_max, res.v_max)
  val mx = buf_get32(meta, META_MCU_X)
  val my = buf_get32(meta, META_MCU_Y)
in
  setup_comps_loop(airlock_nat(MAX_REC_FUEL), meta, c, w, h, res.h_max, res.v_max, mx, my, 0)
end

fun parse_sof_body(src: !Buf, bst: &JpgBits >> _, meta: !Buf, prog: int, len: int, w: int, h: int, c: int): bool = let
  val () = buf_set32(meta, META_WIDTH, w)
  val () = buf_set32(meta, META_HEIGHT, h)
  val () = buf_set32(meta, META_NCOMP, c)
  val () = buf_set32(meta, META_PROGRESSIVE, prog)
  val res = parse_sof_comps(airlock_nat(MAX_REC_FUEL), src, iadd(bst.src_pos, 8), meta, c, 0, 1, 1)
  val () = bst.src_pos := iadd(bst.src_pos, len)
  val valid_subs = check_subsampling(airlock_nat(MAX_REC_FUEL), meta, c, res.h_max, res.v_max, 0)
in
  if not(valid_subs) then false
  else let
    val () = sof_setup_meta(meta, w, h, c, res)
  in true end
end

fun parse_sof(src: !Buf, nsrc: int, bst: &JpgBits >> _, meta: !Buf, prog: int): bool = let
  val len = be16_at(src, bst.src_pos)
  val p = buf_get(src, iadd(bst.src_pos, 2))
  val h = be16_at(src, iadd(bst.src_pos, 3))
  val w = be16_at(src, iadd(bst.src_pos, 5))
  val c = buf_get(src, iadd(bst.src_pos, 7))
in
  if ine(p, 8) orelse ile(w, 0) orelse ile(h, 0) orelse igt(w, JPG_MAX_DIM_PIXELS)
     orelse igt(h, JPG_MAX_DIM_PIXELS) orelse (c <> 1 andalso c <> 3 andalso c <> 4)
     orelse ine(len, iadd(8, imul(c, 3))) orelse igt(iadd(bst.src_pos, len), nsrc) then false
  else parse_sof_body(src, bst, meta, prog, len, w, h, c)
end

fun find_comp_id {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), meta: !Buf, ncomp: int, cid: int, i: int): int =
  if recursion_fuel_available(recfuel) then (
    if ige(i, ncomp) then ~1
    else if ieq(comp_get(meta, i, COMP_ID), cid) then i
    else find_comp_id(recfuel - 1, meta, ncomp, cid, iadd(i, 1))
  ) else ~1

fun parse_sos_comps {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, p: int, meta: !Buf, ncomp: int, ns: int, i: int): bool =
  if recursion_fuel_available(recfuel) then (
    if ige(i, ns) then true
    else let
      val cid = buf_get(src, p)
      val q = buf_get(src, iadd(p, 1))
      val which = find_comp_id(airlock_nat(MAX_REC_FUEL), meta, ncomp, cid, 0)
    in
      if ilt(which, 0) orelse ige(ishr(q, 4), JPG_MAX_TABLES) orelse ige(iand(q, 15), JPG_MAX_TABLES) then false
      else let
        val () = comp_set(meta, which, COMP_HD, ishr(q, 4))
        val () = comp_set(meta, which, COMP_HA, iand(q, 15))
        val () = order_set(meta, i, which)
      in
        parse_sos_comps(recfuel - 1, src, iadd(p, 2), meta, ncomp, ns, iadd(i, 1))
      end
    end
  ) else false

fun sos_init_scan(src: !Buf, bst: &JpgBits >> _, meta: !Buf, len: int, ns: int): void = let
  val p_spec = iadd(bst.src_pos, iadd(3, imul(ns, 2)))
  val ss = buf_get(src, p_spec)
  val se = buf_get(src, iadd(p_spec, 1))
  val aa = buf_get(src, iadd(p_spec, 2))
  val () = buf_set32(meta, META_SPEC_START, ss)
  val () = buf_set32(meta, META_SPEC_END, se)
  val () = buf_set32(meta, META_SUCC_HIGH, ishr(aa, 4))
  val () = buf_set32(meta, META_SUCC_LOW, iand(aa, 15))
  val () = bst.src_pos := iadd(bst.src_pos, len)
  val () = bst.code_buf := 0
  val () = bst.code_bits := 0
  val () = bst.nomore := 0
  val () = bst.marker := JPG_MARK_NONE
in
end

fun jpeg_scan_parameters_valid(meta: !Buf): bool = let
  val start = buf_get32(meta, META_SPEC_START)
  val finish = buf_get32(meta, META_SPEC_END)
  val high = buf_get32(meta, META_SUCC_HIGH)
  val low = buf_get32(meta, META_SUCC_LOW)
  val progressive = buf_get32(meta, META_PROGRESSIVE)
in
  if ieq(progressive, 0) then ieq(start, 0) andalso ieq(high, 0) andalso ieq(low, 0)
  else ile(start, JPG_DCT_BLOCK_SIZE - 1) andalso ile(finish, JPG_DCT_BLOCK_SIZE - 1)
    andalso ile(start, finish) andalso ile(high, JPG_MAX_SUCCESSIVE_BITS) andalso ile(low, JPG_MAX_SUCCESSIVE_BITS)
    andalso (ieq(high, 0) orelse ieq(high, iadd(low, 1)))
    andalso (if ieq(start, 0) then ieq(finish, 0) else ieq(buf_get32(meta, META_SCAN_N), 1))
end

fun parse_sos(src: !Buf, nsrc: int, bst: &JpgBits >> _, meta: !Buf): bool = let
  val len = be16_at(src, bst.src_pos)
  val ns = buf_get(src, iadd(bst.src_pos, 2))
  val ncomp = buf_get32(meta, META_NCOMP)
in
  if ilt(ns, 1) orelse igt(ns, 4) orelse igt(ns, ncomp)
     orelse ine(len, iadd(6, imul(ns, 2))) orelse igt(iadd(bst.src_pos, len), nsrc) then false
  else let
    val () = buf_set32(meta, META_SCAN_N, ns)
    val ok = parse_sos_comps(airlock_nat(MAX_REC_FUEL), src, iadd(bst.src_pos, 3), meta, ncomp, ns, 0)
  in
    if not(ok) then false
    else let
      val () = sos_init_scan(src, bst, meta, len, ns)
    in jpeg_scan_parameters_valid(meta) end
  end
end

fun skip_marker_segment(src: !Buf, nsrc: int, bst: &JpgBits >> _): bool = let
  val len = be16_at(src, bst.src_pos)
  val next_p = iadd(bst.src_pos, len)
in
  if ilt(len, 2) orelse igt(next_p, nsrc) then false
  else let
    val () = bst.src_pos := next_p
  in true end
end

#endif
