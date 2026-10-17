#ifndef ANTHRACITE_JPEG_BASELINE_HATS
#define ANTHRACITE_JPEG_BASELINE_HATS

(* A non-interleaved scan counts one 8x8 block per MCU, even when its
   component has sampling factors greater than one in the frame header. *)
fun decode_baseline_single_loop {fuel:nat} .<fuel>. (
  fuel: int(fuel), src: !Buf, nsrc: int, meta: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf,
  dqt: !Buf, planes: !Buf, scratch: !Buf, block: !Buf, component: int,
  x: int, y: int, width: int, height: int, bits: &JpgBits >> _, scan: &ScanState >> _
): bool =
  if fuel > 0 then (
    if ige(y, height) then true
    else if ige(x, width) then decode_baseline_single_loop(fuel - 1, src, nsrc, meta, hdc, hac, fab, dqt, planes, scratch, block, component, 0, iadd(y, 1), width, height, bits, scan)
    else let
      val ok = decode_mcu_subblock(src, nsrc, meta, hdc, hac, fab, dqt, planes, scratch, block, component, imul(x, JPG_BLOCK_SIDE_PIXELS), imul(y, JPG_BLOCK_SIDE_PIXELS), bits)
      val restart_ok: bool = if ok then check_restart(src, nsrc, meta, bits, scan, scan_has_more(x, y, width, height)) else false
    in
      if restart_ok then decode_baseline_single_loop(fuel - 1, src, nsrc, meta, hdc, hac, fab, dqt, planes, scratch, block, component, iadd(x, 1), y, width, height, bits, scan)
      else false
    end
  ) else false

fun decode_baseline_single_comp(src: !Buf, nsrc: int, meta: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, dqt: !Buf, planes: !Buf, scratch: !Buf, block: !Buf, bits: &JpgBits >> _, scan: &ScanState >> _): bool = let
  val component = order_get(meta, 0)
  val width = idiv(iadd(comp_get(meta, component, COMP_X), JPG_BLOCK_SIDE_PIXELS - 1), JPG_BLOCK_SIDE_PIXELS)
  val height = idiv(iadd(comp_get(meta, component, COMP_Y), JPG_BLOCK_SIDE_PIXELS - 1), JPG_BLOCK_SIDE_PIXELS)
in
  decode_baseline_single_loop(airlock_nat(MAX_REC_FUEL), src, nsrc, meta, hdc, hac, fab, dqt, planes, scratch, block, component, 0, 0, width, height, bits, scan)
end

fun decode_one_baseline_scan(src: !Buf, nsrc: int, meta: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, dqt: !Buf, planes: !Buf, scratch: !Buf, block: !Buf, bits: &JpgBits >> _): bool = let
  val () = reset_entropy_for_scan(meta, bits)
  val count = buf_get32(meta, META_SCAN_N)
  var scan: ScanState = scan_state_init(buf_get32(meta, META_RESTART_INTERVAL))
in
  if ieq(count, 1) then decode_baseline_single_comp(src, nsrc, meta, hdc, hac, fab, dqt, planes, scratch, block, bits, scan)
  else let
    val width = buf_get32(meta, META_MCU_X)
    val height = buf_get32(meta, META_MCU_Y)
  in
    decode_baseline_scan_loop(airlock_nat(MAX_REC_FUEL), src, nsrc, meta, hdc, hac, fab, dqt, planes, scratch, block, 0, 0, width, height, count, bits, scan)
  end
end

fun mark_baseline_components {fuel:nat} .<fuel>. (fuel: int(fuel), meta: !Buf, index: int, count: int): void =
  if fuel > 0 then (
    if ilt(index, count) then let
      val component_bit = ishl(1, order_get(meta, index))
      val decoded = buf_get32(meta, META_DECODED_COMPONENTS)
      val () = buf_set32(meta, META_DECODED_COMPONENTS, ior(decoded, component_bit))
    in
      mark_baseline_components(fuel - 1, meta, iadd(index, 1), count)
    end else ()
  ) else ()

fun baseline_scan_step(src: !Buf, nsrc: int, bits: &JpgBits >> _, meta: !Buf, dqt: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, planes: !Buf, scratch: !Buf, block: !Buf, marker: int, next_marker: &int >> _): bool =
  if ieq(marker, JPG_MARK_SOS) then let
    val header_ok = parse_sos(src, nsrc, bits, meta)
    val ok = if header_ok then decode_one_baseline_scan(src, nsrc, meta, hdc, hac, fab, dqt, planes, scratch, block, bits) else false
    val () = if ok then mark_baseline_components(airlock_nat(MAX_REC_FUEL), meta, 0, buf_get32(meta, META_SCAN_N)) else ()
    val () = next_marker := get_marker_after_scan(src, nsrc, bits)
  in ok end
  else let
    val ok = process_marker(src, nsrc, bits, meta, dqt, hdc, hac, fab, marker)
    val () = next_marker := get_marker(src, nsrc, bits)
  in ok end

fun baseline_scans_loop {fuel:nat} .<fuel>. (
  fuel: int(fuel), src: !Buf, nsrc: int, bits: &JpgBits >> _, meta: !Buf, dqt: !Buf,
  hdc: !Buf, hac: !Buf, fab: !Buf, planes: !Buf, scratch: !Buf, block: !Buf, marker: int
): bool =
  if fuel > 0 then (
    if ieq(marker, JPG_MARK_EOI) then ieq(buf_get32(meta, META_DECODED_COMPONENTS), bmask(buf_get32(meta, META_NCOMP)))
    else if ieq(marker, JPG_MARK_NONE) then false
    else let
      var next_marker: int = JPG_MARK_NONE
      val ok = baseline_scan_step(src, nsrc, bits, meta, dqt, hdc, hac, fab, planes, scratch, block, marker, next_marker)
    in
      if not(ok) then false
      else baseline_scans_loop(fuel - 1, src, nsrc, bits, meta, dqt, hdc, hac, fab, planes, scratch, block, next_marker)
    end
  ) else false

fun decode_baseline_all(src: !Buf, nsrc: int, meta: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, dqt: !Buf, planes: !Buf, scratch: !Buf, block: !Buf, bits: &JpgBits >> _): bool = let
  val marker = get_marker(src, nsrc, bits)
in
  baseline_scans_loop(airlock_nat(MAX_REC_FUEL), src, nsrc, bits, meta, dqt, hdc, hac, fab, planes, scratch, block, marker)
end

#endif
