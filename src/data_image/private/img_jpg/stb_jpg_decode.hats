#ifndef ANTHRACITE_STB_JPG_DECODE_HATS
#define ANTHRACITE_STB_JPG_DECODE_HATS

typedef PlaneSizes = @{plane_bytes= int, coeff_words= int}

fun calc_plane_offsets(meta: !Buf, ncomp: int): PlaneSizes = let
  fun loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), meta: !Buf, ncomp: int, i: int, poff: int, coff: int): PlaneSizes =
    if recursion_fuel_available(recfuel) then (
      if ige(i, ncomp) then @{plane_bytes= poff, coeff_words= coff}
      else let
        val w2 = comp_get(meta, i, COMP_W2)
        val h2 = comp_get(meta, i, COMP_H2)
        val sz = imul(w2, h2)
        val () = comp_set(meta, i, COMP_PLANE_OFF, poff)
        val () = comp_set(meta, i, COMP_COEFF_OFF, coff)
      in
        loop(recfuel - 1, meta, ncomp, iadd(i, 1), iadd(poff, sz), iadd(coff, sz))
      end
    ) else @{plane_bytes= poff, coeff_words= coff}
in
  loop(airlock_nat(MAX_REC_FUEL), meta, ncomp, 0, 0, 0)
end

fun decode_mcu_subblock(src: !Buf, nsrc: int, meta: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, dqt: !Buf, planes: !Buf, val_b: !Buf, blk_data: !Buf, c_idx: int, px: int, py: int, bst: &JpgBits >> _): bool = let
  val ok = decode_block_baseline(src, nsrc, meta, hdc, hac, fab, dqt, c_idx, blk_data, 0, bst)
in
  if not(ok) then false
  else let
    val w2 = comp_get(meta, c_idx, COMP_W2)
    val poff = comp_get(meta, c_idx, COMP_PLANE_OFF)
    val dest_off = iadd(poff, iadd(imul(py, w2), px))
    val () = stbi_idct_block(planes, dest_off, w2, blk_data, 0, val_b)
  in true end
end

fun decode_mcu_comp_y {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, nsrc: int, meta: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, dqt: !Buf, planes: !Buf, val_b: !Buf, blk_data: !Buf, c_idx: int, mx: int, my: int, ch: int, cv: int, y: int, x: int, bst: &JpgBits >> _): bool =
  if recursion_fuel_available(recfuel) then (
    if ige(y, cv) then true
    else if ige(x, ch) then decode_mcu_comp_y(recfuel - 1, src, nsrc, meta, hdc, hac, fab, dqt, planes, val_b, blk_data, c_idx, mx, my, ch, cv, iadd(y, 1), 0, bst)
    else let
      val px = imul(iadd(imul(mx, ch), x), 8)
      val py = imul(iadd(imul(my, cv), y), 8)
      val ok = decode_mcu_subblock(src, nsrc, meta, hdc, hac, fab, dqt, planes, val_b, blk_data, c_idx, px, py, bst)
    in
      if not(ok) then false
      else decode_mcu_comp_y(recfuel - 1, src, nsrc, meta, hdc, hac, fab, dqt, planes, val_b, blk_data, c_idx, mx, my, ch, cv, y, iadd(x, 1), bst)
    end
  ) else false

fun decode_mcu_comps {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, nsrc: int, meta: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, dqt: !Buf, planes: !Buf, val_b: !Buf, blk_data: !Buf, mx: int, my: int, ns: int, k: int, bst: &JpgBits >> _): bool =
  if recursion_fuel_available(recfuel) then (
    if ige(k, ns) then true
    else let
      val c_idx = order_get(meta, k)
      val ch = comp_get(meta, c_idx, COMP_H)
      val cv = comp_get(meta, c_idx, COMP_V)
      val ok = decode_mcu_comp_y(airlock_nat(MAX_REC_FUEL), src, nsrc, meta, hdc, hac, fab, dqt, planes, val_b, blk_data, c_idx, mx, my, ch, cv, 0, 0, bst)
    in
      if not(ok) then false
      else decode_mcu_comps(recfuel - 1, src, nsrc, meta, hdc, hac, fab, dqt, planes, val_b, blk_data, mx, my, ns, iadd(k, 1), bst)
    end
  ) else false

fun decode_baseline_scan_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, nsrc: int, meta: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, dqt: !Buf, planes: !Buf, val_b: !Buf, blk_data: !Buf, mx: int, my: int, mcu_x: int, mcu_y: int, ns: int, bst: &JpgBits >> _, sst: &ScanState >> _): bool =
  if recursion_fuel_available(recfuel) then (
    if ige(my, mcu_y) then true
    else if ige(mx, mcu_x) then decode_baseline_scan_loop(recfuel - 1, src, nsrc, meta, hdc, hac, fab, dqt, planes, val_b, blk_data, 0, iadd(my, 1), mcu_x, mcu_y, ns, bst, sst)
    else let
      val ok = decode_mcu_comps(airlock_nat(MAX_REC_FUEL), src, nsrc, meta, hdc, hac, fab, dqt, planes, val_b, blk_data, mx, my, ns, 0, bst)
    in
      if not(ok) then false
      else let
        val rst_ok = check_restart(src, nsrc, meta, bst, sst, scan_has_more(mx, my, mcu_x, mcu_y))
      in
        if not(rst_ok) then false
        else decode_baseline_scan_loop(recfuel - 1, src, nsrc, meta, hdc, hac, fab, dqt, planes, val_b, blk_data, iadd(mx, 1), my, mcu_x, mcu_y, ns, bst, sst)
      end
    end
  ) else false

fun decode_prog_block_at(src: !Buf, nsrc: int, meta: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, coeffs: !Buf, c_idx: int, bx: int, by: int, bst: &JpgBits >> _, sst: &ScanState >> _): bool = let
  val cw = comp_get(meta, c_idx, COMP_COEFF_W)
  val coff = comp_get(meta, c_idx, COMP_COEFF_OFF)
  val dbase = iadd(coff, imul(iadd(bx, imul(by, cw)), 64))
  val ss = buf_get32(meta, META_SPEC_START)
in
  if ieq(ss, 0) then decode_block_prog_dc(src, nsrc, meta, hdc, c_idx, coeffs, dbase, bst)
  else decode_block_prog_ac(src, nsrc, meta, hac, fab, c_idx, coeffs, dbase, bst, sst)
end

fun decode_prog_mcu_comp {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, nsrc: int, meta: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, coeffs: !Buf, c_idx: int, mx: int, my: int, ch: int, cv: int, y: int, x: int, bst: &JpgBits >> _, sst: &ScanState >> _): bool =
  if recursion_fuel_available(recfuel) then (
    if ige(y, cv) then true
    else if ige(x, ch) then decode_prog_mcu_comp(recfuel - 1, src, nsrc, meta, hdc, hac, fab, coeffs, c_idx, mx, my, ch, cv, iadd(y, 1), 0, bst, sst)
    else let
      val bx = iadd(imul(mx, ch), x)
      val by = iadd(imul(my, cv), y)
      val ok = decode_prog_block_at(src, nsrc, meta, hdc, hac, fab, coeffs, c_idx, bx, by, bst, sst)
    in
      if not(ok) then false
      else decode_prog_mcu_comp(recfuel - 1, src, nsrc, meta, hdc, hac, fab, coeffs, c_idx, mx, my, ch, cv, y, iadd(x, 1), bst, sst)
    end
  ) else false

fun decode_prog_mcu_comps {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, nsrc: int, meta: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, coeffs: !Buf, mx: int, my: int, ns: int, k: int, bst: &JpgBits >> _, sst: &ScanState >> _): bool =
  if recursion_fuel_available(recfuel) then (
    if ige(k, ns) then true
    else let
      val c_idx = order_get(meta, k)
      val ch = comp_get(meta, c_idx, COMP_H)
      val cv = comp_get(meta, c_idx, COMP_V)
      val ok = decode_prog_mcu_comp(airlock_nat(MAX_REC_FUEL), src, nsrc, meta, hdc, hac, fab, coeffs, c_idx, mx, my, ch, cv, 0, 0, bst, sst)
    in
      if not(ok) then false
      else decode_prog_mcu_comps(recfuel - 1, src, nsrc, meta, hdc, hac, fab, coeffs, mx, my, ns, iadd(k, 1), bst, sst)
    end
  ) else false

fun decode_prog_scan_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, nsrc: int, meta: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, coeffs: !Buf, mx: int, my: int, mcu_x: int, mcu_y: int, ns: int, bst: &JpgBits >> _, sst: &ScanState >> _): bool =
  if recursion_fuel_available(recfuel) then (
    if ige(my, mcu_y) then true
    else if ige(mx, mcu_x) then decode_prog_scan_loop(recfuel - 1, src, nsrc, meta, hdc, hac, fab, coeffs, 0, iadd(my, 1), mcu_x, mcu_y, ns, bst, sst)
    else let
      val ok = decode_prog_mcu_comps(airlock_nat(MAX_REC_FUEL), src, nsrc, meta, hdc, hac, fab, coeffs, mx, my, ns, 0, bst, sst)
    in
      if not(ok) then false
      else let
        val rst_ok = check_restart(src, nsrc, meta, bst, sst, scan_has_more(mx, my, mcu_x, mcu_y))
      in
        if not(rst_ok) then false
        else decode_prog_scan_loop(recfuel - 1, src, nsrc, meta, hdc, hac, fab, coeffs, iadd(mx, 1), my, mcu_x, mcu_y, ns, bst, sst)
      end
    end
  ) else false

fun finish_prog_comp_block(meta: !Buf, coeffs: !Buf, planes: !Buf, dqt: !Buf, val_b: !Buf, c_idx: int, bx: int, by: int): void = let
  val cw = comp_get(meta, c_idx, COMP_COEFF_W)
  val coff = comp_get(meta, c_idx, COMP_COEFF_OFF)
  val poff = comp_get(meta, c_idx, COMP_PLANE_OFF)
  val w2 = comp_get(meta, c_idx, COMP_W2)
  val tq = comp_get(meta, c_idx, COMP_TQ)
  val sbase = iadd(coff, imul(iadd(bx, imul(by, cw)), 64))
  val dbase = iadd(poff, iadd(imul(imul(by, 8), w2), imul(bx, 8)))
  val () = dequantize_block(coeffs, sbase, dqt, tq)
in
  stbi_idct_block(planes, dbase, w2, coeffs, sbase, val_b)
end

fun finish_prog_blocks_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), meta: !Buf, coeffs: !Buf, planes: !Buf, dqt: !Buf, val_b: !Buf, c_idx: int, cw: int, ch: int, bx: int, by: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(by, ch) then ()
    else if ige(bx, cw) then finish_prog_blocks_loop(recfuel - 1, meta, coeffs, planes, dqt, val_b, c_idx, cw, ch, 0, iadd(by, 1))
    else let
      val () = finish_prog_comp_block(meta, coeffs, planes, dqt, val_b, c_idx, bx, by)
    in
      finish_prog_blocks_loop(recfuel - 1, meta, coeffs, planes, dqt, val_b, c_idx, cw, ch, iadd(bx, 1), by)
    end
  ) else ()

fun finish_prog_comps_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), meta: !Buf, coeffs: !Buf, planes: !Buf, dqt: !Buf, val_b: !Buf, ncomp: int, i: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(i, ncomp) then ()
    else let
      val cx = comp_get(meta, i, COMP_X)
      val cy = comp_get(meta, i, COMP_Y)
      val cw = ishr(iadd(cx, 7), 3)
      val ch = ishr(iadd(cy, 7), 3)
      val () = finish_prog_blocks_loop(airlock_nat(MAX_REC_FUEL), meta, coeffs, planes, dqt, val_b, i, cw, ch, 0, 0)
    in
      finish_prog_comps_loop(recfuel - 1, meta, coeffs, planes, dqt, val_b, ncomp, iadd(i, 1))
    end
  ) else ()

fun finish_prog_all(meta: !Buf, coeffs: !Buf, planes: !Buf, dqt: !Buf, val_b: !Buf): void = let
  val ncomp = buf_get32(meta, META_NCOMP)
in
  finish_prog_comps_loop(airlock_nat(MAX_REC_FUEL), meta, coeffs, planes, dqt, val_b, ncomp, 0)
end

typedef ResampleRows = @{near_y= int, far_y= int}

fun calc_resample_rows_v2(j: int, cy: int): ResampleRows =
  if ieq(iand(j, 1), 0) then let
    val yn = ishr(j, 1)
    val yf = if igt(yn, 0) then isub(yn, 1) else 0
  in @{near_y= yn, far_y= yf} end
  else let
    val yn = ishr(j, 1)
    val y1 = iadd(yn, 1)
    val yf = if ilt(y1, cy) then y1 else yn
  in @{near_y= yn, far_y= yf} end

fun calc_resample_rows(j: int, vs: int, cy: int): ResampleRows =
  if ieq(vs, 1) then @{near_y= j, far_y= j}
  else if ieq(vs, 2) then calc_resample_rows_v2(j, cy)
  else let
    (* Generic resampling is nearest-neighbour, without the v2 filter. *)
    val y0 = imin(idiv(j, vs), isub(cy, 1))
  in
    @{near_y= y0, far_y= y0}
  end

fun resample_comp_line(meta: !Buf, planes: !Buf, lbuf: !Buf, c_idx: int, j: int, w: int): void = let
  val h_max = buf_get32(meta, META_HMAX)
  val v_max = buf_get32(meta, META_VMAX)
  val ch = comp_get(meta, c_idx, COMP_H)
  val cv = comp_get(meta, c_idx, COMP_V)
  val hs = idiv(h_max, ch)
  val vs = idiv(v_max, cv)
  val w2 = comp_get(meta, c_idx, COMP_W2)
  val poff = comp_get(meta, c_idx, COMP_PLANE_OFF)
  val cy = comp_get(meta, c_idx, COMP_Y)
  val rr = calc_resample_rows(j, vs, cy)
  val noff = iadd(poff, imul(rr.near_y, w2))
  val foff = iadd(poff, imul(rr.far_y, w2))
  val w_lores = idiv(iadd(w, isub(hs, 1)), hs)
in
  dispatch_resample_row(lbuf, 0, planes, noff, foff, w_lores, hs, vs)
end

fun render_scanlines_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), meta: !Buf, planes: !Buf, out_buf: !Buf, lb0: !Buf, lb1: !Buf, lb2: !Buf, lb3: !Buf, w: int, h: int, ncomp: int, color: JpegColorSpace, j: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(j, h) then ()
    else let
      val () = resample_comp_line(meta, planes, lb0, 0, j, w)
      val () = if ige(ncomp, 3) then resample_comp_line(meta, planes, lb1, 1, j, w) else ()
      val () = if ige(ncomp, 3) then resample_comp_line(meta, planes, lb2, 2, j, w) else ()
      val () = if ieq(ncomp, JPG_MAX_COMPONENTS) then resample_comp_line(meta, planes, lb3, 3, j, w) else ()
      val dest_off = imul(imul(j, w), JPG_COLOR_CHANNELS)
      val () = jpeg_render_color_row(airlock_nat(MAX_REC_FUEL), out_buf, dest_off, lb0, lb1, lb2, lb3, w, color, 0)
    in
      render_scanlines_loop(recfuel - 1, meta, planes, out_buf, lb0, lb1, lb2, lb3, w, h, ncomp, color, iadd(j, 1))
    end
  ) else ()

fun resample_image_to_rgba(meta: !Buf, planes: !Buf, out_buf: !Buf, lb0: !Buf, lb1: !Buf, lb2: !Buf, lb3: !Buf): void = let
  val w = buf_get32(meta, META_WIDTH)
  val h = buf_get32(meta, META_HEIGHT)
  val ncomp = buf_get32(meta, META_NCOMP)
  val color = jpeg_color_space(meta)
in
  render_scanlines_loop(airlock_nat(MAX_REC_FUEL), meta, planes, out_buf, lb0, lb1, lb2, lb3, w, h, ncomp, color, 0)
end

fun process_marker(src: !Buf, nsrc: int, bst: &JpgBits >> _, meta: !Buf, dqt: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, m: int): bool =
  if ieq(m, JPG_MARK_DQT) then parse_dqt(src, nsrc, bst, dqt)
  else if ieq(m, JPG_MARK_DHT) then parse_dht(src, nsrc, bst, hdc, hac, fab)
  else if ieq(m, JPG_MARK_DRI) then parse_dri(src, nsrc, bst, meta)
  else if ieq(m, JPG_MARK_APP0) orelse ieq(m, JPG_MARK_APP14) then parse_color_marker(src, nsrc, bst, meta, m)
  else skip_marker_segment(src, nsrc, bst)

fun find_sof_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, nsrc: int, bst: &JpgBits >> _, meta: !Buf, dqt: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf): bool =
  if recursion_fuel_available(recfuel) then let
    val m = get_marker(src, nsrc, bst)
  in
    if ieq(m, JPG_MARK_SOF0) orelse ieq(m, JPG_MARK_SOF1) then parse_sof(src, nsrc, bst, meta, 0)
    else if ieq(m, JPG_MARK_SOF2) then parse_sof(src, nsrc, bst, meta, 1)
    else if ieq(m, JPG_MARK_EOI) orelse ieq(m, JPG_MARK_NONE) then false
    else let
      val ok = process_marker(src, nsrc, bst, meta, dqt, hdc, hac, fab, m)
    in
      if not(ok) then false
      else find_sof_loop(recfuel - 1, src, nsrc, bst, meta, dqt, hdc, hac, fab)
    end
  end else false

fun skip_jpeg_junk {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, nsrc: int, bst: &JpgBits >> _): int =
  if recursion_fuel_available(recfuel) then (
    if ige(bst.src_pos, nsrc) then JPG_MARK_NONE
    else let
      val x = buf_get(src, bst.src_pos)
      val () = bst.src_pos := iadd(bst.src_pos, 1)
    in
      if ine(x, 255) then skip_jpeg_junk(recfuel - 1, src, nsrc, bst)
      else let
        val res = skip_ff_bytes(airlock_nat(MAX_REC_FUEL), src, nsrc, bst.src_pos)
        val () = bst.src_pos := res.pos
      in
        if ine(res.mark, 0) andalso ine(res.mark, JPG_MARK_NONE) then res.mark
        else skip_jpeg_junk(recfuel - 1, src, nsrc, bst)
      end
    end
  ) else JPG_MARK_NONE

fun decode_prog_single_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, nsrc: int, meta: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, coeffs: !Buf, c_idx: int, bx: int, by: int, bw: int, bh: int, bst: &JpgBits >> _, sst: &ScanState >> _): bool =
  if recursion_fuel_available(recfuel) then (
    if ige(by, bh) then true
    else if ige(bx, bw) then decode_prog_single_loop(recfuel - 1, src, nsrc, meta, hdc, hac, fab, coeffs, c_idx, 0, iadd(by, 1), bw, bh, bst, sst)
    else let
      val ok = decode_prog_block_at(src, nsrc, meta, hdc, hac, fab, coeffs, c_idx, bx, by, bst, sst)
    in
      if not(ok) then false
      else let
        val rst_ok = check_restart(src, nsrc, meta, bst, sst, scan_has_more(bx, by, bw, bh))
      in
        if not(rst_ok) then false
        else decode_prog_single_loop(recfuel - 1, src, nsrc, meta, hdc, hac, fab, coeffs, c_idx, iadd(bx, 1), by, bw, bh, bst, sst)
      end
    end
  ) else false

fun reset_entropy_for_scan(meta: !Buf, bst: &JpgBits >> _): void = let
  val () = bst.code_buf := 0
  val () = bst.code_bits := 0
  val () = bst.nomore := 0
  val () = bst.marker := JPG_MARK_NONE
  val () = comp_set(meta, 0, COMP_DC_PRED, 0)
  val () = comp_set(meta, 1, COMP_DC_PRED, 0)
  val () = comp_set(meta, 2, COMP_DC_PRED, 0)
  val () = comp_set(meta, 3, COMP_DC_PRED, 0)
in () end

fun decode_prog_single_comp(src: !Buf, nsrc: int, meta: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, coeffs: !Buf, bst: &JpgBits >> _, sst: &ScanState >> _): bool = let
  val c_idx = order_get(meta, 0)
  val cx = comp_get(meta, c_idx, COMP_X)
  val cy = comp_get(meta, c_idx, COMP_Y)
  val bw = ishr(iadd(cx, 7), 3)
  val bh = ishr(iadd(cy, 7), 3)
in
  decode_prog_single_loop(airlock_nat(MAX_REC_FUEL), src, nsrc, meta, hdc, hac, fab, coeffs, c_idx, 0, 0, bw, bh, bst, sst)
end

fun decode_one_prog_scan(src: !Buf, nsrc: int, meta: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, coeffs: !Buf, bst: &JpgBits >> _): bool = let
  val () = reset_entropy_for_scan(meta, bst)
  val ns = buf_get32(meta, META_SCAN_N)
  val ri = buf_get32(meta, META_RESTART_INTERVAL)
  var sst: ScanState = scan_state_init(ri)
in
  if ieq(ns, 1) then decode_prog_single_comp(src, nsrc, meta, hdc, hac, fab, coeffs, bst, sst)
  else let
    val mcu_x = buf_get32(meta, META_MCU_X)
    val mcu_y = buf_get32(meta, META_MCU_Y)
  in
    decode_prog_scan_loop(airlock_nat(MAX_REC_FUEL), src, nsrc, meta, hdc, hac, fab, coeffs, 0, 0, mcu_x, mcu_y, ns, bst, sst)
  end
end

fun get_marker_after_scan(src: !Buf, nsrc: int, bst: &JpgBits >> _): int = let
  val m0 = if bst.marker <> JPG_MARK_NONE then bst.marker else skip_jpeg_junk(airlock_nat(MAX_REC_FUEL), src, nsrc, bst)
  val () = bst.marker := JPG_MARK_NONE
in
  if is_restart_marker(m0) then get_marker(src, nsrc, bst)
  else m0
end

fun prog_scan_step(src: !Buf, nsrc: int, bst: &JpgBits >> _, meta: !Buf, dqt: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, coeffs: !Buf, m: int, m_next: &int >> _): bool =
  if ieq(m, JPG_MARK_SOS) then let
    val ok_sos = parse_sos(src, nsrc, bst, meta)
  in
    if not(ok_sos) then false
    else let
      val ok = decode_one_prog_scan(src, nsrc, meta, hdc, hac, fab, coeffs, bst)
      val () = m_next := get_marker_after_scan(src, nsrc, bst)
    in ok end
  end else let
    val ok = process_marker(src, nsrc, bst, meta, dqt, hdc, hac, fab, m)
    val () = m_next := get_marker(src, nsrc, bst)
  in ok end

fun prog_scans_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, nsrc: int, bst: &JpgBits >> _, meta: !Buf, dqt: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, coeffs: !Buf, m: int): bool =
  if recursion_fuel_available(recfuel) then (
    if ieq(m, JPG_MARK_EOI) orelse ieq(m, JPG_MARK_NONE) then true
    else let
      var m_next: int = JPG_MARK_NONE
      val ok = prog_scan_step(src, nsrc, bst, meta, dqt, hdc, hac, fab, coeffs, m, m_next)
    in
      if not(ok) then false
      else prog_scans_loop(recfuel - 1, src, nsrc, bst, meta, dqt, hdc, hac, fab, coeffs, m_next)
    end
  ) else false

#include "data_image/private/img_jpg/jpeg_baseline.hats"

fun render_rgba_output(meta: !Buf, planes: !Buf, out_buf: !Buf, w: int): void = let
  val lb0 = buf_make(iadd(w, JPG_MAX_SAMPLE_FACTOR))
  val lb1 = buf_make(iadd(w, JPG_MAX_SAMPLE_FACTOR))
  val lb2 = buf_make(iadd(w, JPG_MAX_SAMPLE_FACTOR))
  val lb3 = buf_make(iadd(w, JPG_MAX_SAMPLE_FACTOR))
  val () = resample_image_to_rgba(meta, planes, out_buf, lb0, lb1, lb2, lb3)
  val () = buf_free(lb0)
  val () = buf_free(lb1)
  val () = buf_free(lb2)
  val () = buf_free(lb3)
in () end

fun decode_image_pass(src: !Buf, nsrc: int, meta: !Buf, dqt: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, val_b: !Buf, blk_data: !Buf, planes: !Buf, prog: int, ps_coeff_words: int, bst: &JpgBits >> _): bool =
  if prog <> 0 then let
    val coeffs = buf_make(imul(ps_coeff_words, 4))
    val m = get_marker(src, nsrc, bst)
    val ok = prog_scans_loop(airlock_nat(MAX_REC_FUEL), src, nsrc, bst, meta, dqt, hdc, hac, fab, coeffs, m)
    val () = if ok then finish_prog_all(meta, coeffs, planes, dqt, val_b) else ()
    val () = buf_free(coeffs)
  in ok end
  else decode_baseline_all(src, nsrc, meta, hdc, hac, fab, dqt, planes, val_b, blk_data, bst)

fun finish_and_render(meta: !Buf, planes: Buf, ok: bool, wout: &int >> _, hout: &int >> _): Buf =
  if not(ok) then let
    val () = buf_free(planes)
    val () = wout := 0
    val () = hout := 0
  in buf_make(4) end
  else let
    val w = buf_get32(meta, META_WIDTH)
    val h = buf_get32(meta, META_HEIGHT)
    val size_bytes = imul(imul(w, h), JPG_COLOR_CHANNELS)
    val out_buf = buf_make(size_bytes)
    val () = render_rgba_output(meta, planes, out_buf, w)
    val () = buf_set_len(out_buf, size_bytes)
    val () = buf_free(planes)
    val () = wout := w
    val () = hout := h
  in out_buf end

fun free_jpg_work_buffers(meta: Buf, dqt: Buf, hdc: Buf, hac: Buf, fab: Buf, val_b: Buf, blk_data: Buf): void = let
  val () = buf_free(meta)
  val () = buf_free(dqt)
  val () = buf_free(hdc)
  val () = buf_free(hac)
  val () = buf_free(fab)
  val () = buf_free(val_b)
  val () = buf_free(blk_data)
in () end

fun stbi_jpeg_decode_buffers(src: !Buf, nsrc: int, meta: Buf, dqt: Buf, hdc: Buf, hac: Buf, fab: Buf, val_b: Buf, blk_data: Buf, bst: &JpgBits >> _, wout: &int >> _, hout: &int >> _): Buf = let
  val sof_ok = find_sof_loop(airlock_nat(MAX_REC_FUEL), src, nsrc, bst, meta, dqt, hdc, hac, fab)
in
  if not(sof_ok) then let
    val () = free_jpg_work_buffers(meta, dqt, hdc, hac, fab, val_b, blk_data)
    val () = wout := 0
    val () = hout := 0
  in buf_make(4) end
  else let
    val ncomp = buf_get32(meta, META_NCOMP)
    val prog = buf_get32(meta, META_PROGRESSIVE)
    val ps = calc_plane_offsets(meta, ncomp)
    val planes = buf_make(ps.plane_bytes)
    val ok = decode_image_pass(src, nsrc, meta, dqt, hdc, hac, fab, val_b, blk_data, planes, prog, ps.coeff_words, bst)
    val res = finish_and_render(meta, planes, ok, wout, hout)
    val () = free_jpg_work_buffers(meta, dqt, hdc, hac, fab, val_b, blk_data)
  in res end
end

fun alloc_and_decode_jpg(src: !Buf, nsrc: int, wout: &int >> _, hout: &int >> _): Buf = let
  var bst: JpgBits = bitstream_init(2)
  val meta = buf_make(512) and dqt = buf_make(1024)
  val () = buf_set32(meta, META_APP14, JPG_ADOBE_UNKNOWN)
  val hdc = buf_make(imul(HUFF_BUF_WORDS, 4))
  val hac = buf_make(imul(HUFF_BUF_WORDS, 4))
  val fab = buf_make(imul(FAST_AC_BUF_WORDS, 4))
  val val_b = buf_make(256) and blk_data = buf_make(256)
in
  stbi_jpeg_decode_buffers(src, nsrc, meta, dqt, hdc, hac, fab, val_b, blk_data, bst, wout, hout)
end

fun stbi_jpeg_decode_entry(src: !Buf, wout: &int >> _, hout: &int >> _): Buf = let
  val nsrc = buf_len(src)
  val is_valid = igt(nsrc, 3) andalso ieq(buf_get(src, 0), 255) andalso ieq(buf_get(src, 1), 216)
in
  if not(is_valid) then let
    val () = wout := 0 and () = hout := 0
  in buf_make(4) end
  else alloc_and_decode_jpg(src, nsrc, wout, hout)
end

#endif
