#ifndef ANTHRACITE_STB_JPG_SCAN_HATS
#define ANTHRACITE_STB_JPG_SCAN_HATS

typedef ScanState = @{
  todo= int,
  eob_run= int
}

typedef ScanRes = @{ ok= bool, k= int }
typedef AdvanceRes = @{ k= int, done= bool }

fun scan_state_init(ri: int): ScanState =
  @{todo= (if igt(ri, 0) then ri else 2147483647), eob_run= 0}

fun is_restart_marker(m: int): bool =
  ige(m, JPG_MARK_RST0) andalso ile(m, JPG_MARK_RST7)

fun reset_dc_preds {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), meta: !Buf, ncomp: int, i: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(i, ncomp) then ()
    else let
      val () = comp_set(meta, i, COMP_DC_PRED, 0)
    in
      reset_dc_preds(recfuel - 1, meta, ncomp, iadd(i, 1))
    end
  ) else ()

fun scan_reset(meta: !Buf, bst: &JpgBits >> _, sst: &ScanState >> _): void = let
  val ri = buf_get32(meta, META_RESTART_INTERVAL)
  val () = reset_dc_preds(airlock_nat(MAX_REC_FUEL), meta, 4, 0)
  val () = bst.code_buf := 0
  val () = bst.code_bits := 0
  val () = bst.nomore := 0
  val () = bst.marker := JPG_MARK_NONE
  val ri_val = if igt(ri, 0) then ri else 2147483647
  val () = sst.todo := ri_val
  val () = sst.eob_run := 0
in () end

(* Restart markers separate MCUs, never follow the final MCU of a scan. *)
fun scan_has_more(x: int, y: int, width: int, height: int): bool =
  ilt(iadd(x, 1), width) orelse ilt(iadd(y, 1), height)

fun check_restart(src: !Buf, nsrc: int, meta: !Buf, bst: &JpgBits >> _, sst: &ScanState >> _, has_more: bool): bool = let
  val next_todo = isub(sst.todo, 1)
  val () = sst.todo := next_todo
in
  if not(has_more) orelse igt(next_todo, 0) then true
  else let
    val () = if bst.code_bits < 24 then grow_buffer(src, nsrc, bst) else ()
  in
    if is_restart_marker(bst.marker) then let
      val () = scan_reset(meta, bst, sst)
    in true end else false
  end
end

fun decode_block_ac_fast(fab: !Buf, dqt: !Buf, ha: int, tq: int, c: int, data: !Buf, dbase: int, k: int, bst: &JpgBits >> _): ScanRes = let
  val r = fast_ac_get(fab, ha, c)
  val run = iand(ishr(r, 4), 15)
  val s = iand(r, 15)
in
  if igt(s, bst.code_bits) then @{ok= false, k= k}
  else let
    val () = bst.code_buf := ishl(bst.code_buf, s)
    val () = bst.code_bits := isub(bst.code_bits, s)
    val k1 = iadd(k, run)
    val zig = dezigzag(k1)
    val dq = dequant_get(dqt, tq, zig)
    val () = buf_set32(data, iadd(dbase, zig), imul(ashr(r, 8), dq))
  in
    @{ok= true, k= iadd(k1, 1)}
  end
end

fun decode_block_ac_val(src: !Buf, nsrc: int, dqt: !Buf, tq: int, data: !Buf, dbase: int, k1: int, s: int, bst: &JpgBits >> _): ScanRes = let
  val zig = dezigzag(k1)
  val diff = extend_receive(src, nsrc, bst, s)
  val dq = dequant_get(dqt, tq, zig)
  val () = buf_set32(data, iadd(dbase, zig), imul(diff, dq))
in
  @{ok= true, k= iadd(k1, 1)}
end

fun decode_block_ac_slow(src: !Buf, nsrc: int, hac: !Buf, dqt: !Buf, ha: int, tq: int, data: !Buf, dbase: int, k: int, bst: &JpgBits >> _): ScanRes = let
  val rs = huff_decode(src, nsrc, hac, ha, bst)
in
  if ilt(rs, 0) then @{ok= false, k= k}
  else let
    val s = iand(rs, 15)
    val run = iand(ishr(rs, 4), 15)
  in
    if ieq(s, 0) then (if ine(rs, 240) then @{ok= true, k= 64} else @{ok= true, k= iadd(k, 16)})
    else decode_block_ac_val(src, nsrc, dqt, tq, data, dbase, iadd(k, run), s, bst)
  end
end

fun decode_block_ac_step(src: !Buf, nsrc: int, hac: !Buf, fab: !Buf, dqt: !Buf, ha: int, tq: int, data: !Buf, dbase: int, k: int, bst: &JpgBits >> _): ScanRes = let
  val () = if bst.code_bits < 16 then grow_buffer(src, nsrc, bst) else ()
  val c = iand(ishr(bst.code_buf, 23), 511)
  val r = fast_ac_get(fab, ha, c)
in
  if ine(r, 0) then decode_block_ac_fast(fab, dqt, ha, tq, c, data, dbase, k, bst)
  else decode_block_ac_slow(src, nsrc, hac, dqt, ha, tq, data, dbase, k, bst)
end

fun decode_block_ac_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, nsrc: int, hac: !Buf, fab: !Buf, dqt: !Buf, ha: int, tq: int, data: !Buf, dbase: int, k: int, bst: &JpgBits >> _): bool =
  if recursion_fuel_available(recfuel) then (
    if ige(k, 64) then true
    else let
      val res = decode_block_ac_step(src, nsrc, hac, fab, dqt, ha, tq, data, dbase, k, bst)
    in
      if not(res.ok) then false
      else decode_block_ac_loop(recfuel - 1, src, nsrc, hac, fab, dqt, ha, tq, data, dbase, res.k, bst)
    end
  ) else false

fun decode_block_baseline(src: !Buf, nsrc: int, meta: !Buf, hdc: !Buf, hac: !Buf, fab: !Buf, dqt: !Buf, c_idx: int, data: !Buf, dbase: int, bst: &JpgBits >> _): bool = let
  val hd = comp_get(meta, c_idx, COMP_HD)
  val ha = comp_get(meta, c_idx, COMP_HA)
  val tq = comp_get(meta, c_idx, COMP_TQ)
  val t = huff_decode(src, nsrc, hdc, hd, bst)
in
  if ilt(t, 0) orelse igt(t, 15) then false
  else let
    val diff = if igt(t, 0) then extend_receive(src, nsrc, bst, t) else 0
    val dc = iadd(comp_get(meta, c_idx, COMP_DC_PRED), diff)
    val () = comp_set(meta, c_idx, COMP_DC_PRED, dc)
    val () = zero_block(data, dbase)
    val () = buf_set32(data, dbase, imul(dc, dequant_get(dqt, tq, 0)))
  in
    decode_block_ac_loop(airlock_nat(MAX_REC_FUEL), src, nsrc, hac, fab, dqt, ha, tq, data, dbase, 1, bst)
  end
end

fun decode_prog_dc_first(src: !Buf, nsrc: int, meta: !Buf, hdc: !Buf, c_idx: int, data: !Buf, dbase: int, sl: int, bst: &JpgBits >> _): bool = let
  val () = zero_block(data, dbase)
  val hd = comp_get(meta, c_idx, COMP_HD)
  val t = huff_decode(src, nsrc, hdc, hd, bst)
in
  if ilt(t, 0) orelse igt(t, 15) then false
  else let
    val diff = if igt(t, 0) then extend_receive(src, nsrc, bst, t) else 0
    val dc = iadd(comp_get(meta, c_idx, COMP_DC_PRED), diff)
    val () = comp_set(meta, c_idx, COMP_DC_PRED, dc)
    val () = buf_set32(data, dbase, ishl(dc, sl))
  in true end
end

fun decode_prog_dc_refine(src: !Buf, nsrc: int, data: !Buf, dbase: int, sl: int, bst: &JpgBits >> _): bool = let
  val b = get_bit(src, nsrc, bst)
  val cur = buf_get32(data, dbase)
  val () = if ieq(b, 1) then buf_set32(data, dbase, iadd(cur, ishl(1, sl))) else ()
in true end

fun decode_block_prog_dc(src: !Buf, nsrc: int, meta: !Buf, hdc: !Buf, c_idx: int, data: !Buf, dbase: int, bst: &JpgBits >> _): bool = let
  val sh = buf_get32(meta, META_SUCC_HIGH)
  val sl = buf_get32(meta, META_SUCC_LOW)
in
  if ieq(sh, 0) then decode_prog_dc_first(src, nsrc, meta, hdc, c_idx, data, dbase, sl, bst)
  else decode_prog_dc_refine(src, nsrc, data, dbase, sl, bst)
end

fun prog_ac_first_fast(fab: !Buf, ha: int, sl: int, c: int, data: !Buf, dbase: int, k: int, bst: &JpgBits >> _): ScanRes = let
  val r = fast_ac_get(fab, ha, c)
  val run = iand(ishr(r, 4), 15)
  val s = iand(r, 15)
in
  if igt(s, bst.code_bits) then @{ok= false, k= k}
  else let
    val () = bst.code_buf := ishl(bst.code_buf, s)
    val () = bst.code_bits := isub(bst.code_bits, s)
    val k1 = iadd(k, run)
    val zig = dezigzag(k1)
    val () = buf_set32(data, iadd(dbase, zig), ishl(ashr(r, 8), sl))
  in
    @{ok= true, k= iadd(k1, 1)}
  end
end

fun prog_ac_first_eob(src: !Buf, nsrc: int, run: int, bst: &JpgBits >> _, sst: &ScanState >> _): ScanRes = let
  val eob0 = ishl(1, run)
  val eob = if igt(run, 0) then iadd(eob0, get_bits(src, nsrc, bst, run)) else eob0
  val () = sst.eob_run := isub(eob, 1)
in
  @{ok= true, k= 64}
end

fun prog_ac_first_val(src: !Buf, nsrc: int, sl: int, data: !Buf, dbase: int, k1: int, s: int, bst: &JpgBits >> _): ScanRes = let
  val zig = dezigzag(k1)
  val diff = extend_receive(src, nsrc, bst, s)
  val () = buf_set32(data, iadd(dbase, zig), ishl(diff, sl))
in
  @{ok= true, k= iadd(k1, 1)}
end

fun prog_ac_first_slow(src: !Buf, nsrc: int, hac: !Buf, ha: int, sl: int, data: !Buf, dbase: int, k: int, bst: &JpgBits >> _, sst: &ScanState >> _): ScanRes = let
  val rs = huff_decode(src, nsrc, hac, ha, bst)
in
  if ilt(rs, 0) then @{ok= false, k= k}
  else let
    val s = iand(rs, 15)
    val run = iand(ishr(rs, 4), 15)
  in
    if ieq(s, 0) then (
      if ilt(run, 15) then prog_ac_first_eob(src, nsrc, run, bst, sst)
      else @{ok= true, k= iadd(k, 16)}
    ) else prog_ac_first_val(src, nsrc, sl, data, dbase, iadd(k, run), s, bst)
  end
end

fun prog_ac_first_step(src: !Buf, nsrc: int, hac: !Buf, fab: !Buf, ha: int, sl: int, data: !Buf, dbase: int, k: int, bst: &JpgBits >> _, sst: &ScanState >> _): ScanRes = let
  val () = if bst.code_bits < 16 then grow_buffer(src, nsrc, bst) else ()
  val c = iand(ishr(bst.code_buf, 23), 511)
  val r = fast_ac_get(fab, ha, c)
in
  if ine(r, 0) then prog_ac_first_fast(fab, ha, sl, c, data, dbase, k, bst)
  else prog_ac_first_slow(src, nsrc, hac, ha, sl, data, dbase, k, bst, sst)
end

fun prog_ac_first_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, nsrc: int, hac: !Buf, fab: !Buf, ha: int, sl: int, se: int, data: !Buf, dbase: int, k: int, bst: &JpgBits >> _, sst: &ScanState >> _): bool =
  if recursion_fuel_available(recfuel) then (
    if igt(k, se) then true
    else let
      val res = prog_ac_first_step(src, nsrc, hac, fab, ha, sl, data, dbase, k, bst, sst)
    in
      if not(res.ok) then false
      else prog_ac_first_loop(recfuel - 1, src, nsrc, hac, fab, ha, sl, se, data, dbase, res.k, bst, sst)
    end
  ) else false

fun refine_coeff(src: !Buf, nsrc: int, bst: &JpgBits >> _, data: !Buf, dbase: int, zig: int, bit: int): void = let
  val p = buf_get32(data, iadd(dbase, zig))
in
  if ine(p, 0) then let
    val b = get_bit(src, nsrc, bst)
  in
    if ieq(b, 1) andalso ieq(iand(p, bit), 0) then let
      val next_p = if igt(p, 0) then iadd(p, bit) else isub(p, bit)
      val () = buf_set32(data, iadd(dbase, zig), next_p)
    in () end else ()
  end else ()
end

fun refine_block_eob {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, nsrc: int, bst: &JpgBits >> _, data: !Buf, dbase: int, bit: int, k: int, se: int): void =
  if recursion_fuel_available(recfuel) then (
    if igt(k, se) then ()
    else let
      val () = refine_coeff(src, nsrc, bst, data, dbase, dezigzag(k), bit)
    in
      refine_block_eob(recfuel - 1, src, nsrc, bst, data, dbase, bit, iadd(k, 1), se)
    end
  ) else ()

fun refine_advance_run {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, nsrc: int, bst: &JpgBits >> _, data: !Buf, dbase: int, bit: int, s: int, r: int, k: int, se: int): AdvanceRes =
  if recursion_fuel_available(recfuel) then (
    if igt(k, se) then @{k= k, done= true}
    else let
      val zig = dezigzag(k)
      val p = buf_get32(data, iadd(dbase, zig))
      val k_next = iadd(k, 1)
    in
      if ine(p, 0) then let
        val () = refine_coeff(src, nsrc, bst, data, dbase, zig, bit)
      in
        refine_advance_run(recfuel - 1, src, nsrc, bst, data, dbase, bit, s, r, k_next, se)
      end else if ieq(r, 0) then (
        buf_set32(data, iadd(dbase, zig), s); @{k= k_next, done= false}
      ) else refine_advance_run(recfuel - 1, src, nsrc, bst, data, dbase, bit, s, isub(r, 1), k_next, se)
    end
  ) else @{k= k, done= true}

typedef RefineStepRes = @{k= int, ok= bool, done= bool}

fun prog_ac_refine_zero(
  src: !Buf, nsrc: int, bst: &JpgBits >> _, sst: &ScanState >> _,
  data: !Buf, dbase: int, bit: int, se: int, k: int, r0: int
): RefineStepRes =
  if ilt(r0, 15) then let
    val eob0 = isub(ishl(1, r0), 1)
    val eob = if igt(r0, 0) then iadd(eob0, get_bits(src, nsrc, bst, r0)) else eob0
    val () = sst.eob_run := eob
    val adv = refine_advance_run(airlock_nat(MAX_REC_FUEL), src, nsrc, bst, data, dbase, bit, 0, 64, k, se)
  in @{k= adv.k, ok= true, done= true} end
  else let
    val adv = refine_advance_run(airlock_nat(MAX_REC_FUEL), src, nsrc, bst, data, dbase, bit, 0, 15, k, se)
  in @{k= adv.k, ok= true, done= adv.done} end

fun prog_ac_refine_step(
  src: !Buf, nsrc: int, bst: &JpgBits >> _, sst: &ScanState >> _,
  data: !Buf, dbase: int, bit: int, se: int, k: int, rs: int
): RefineStepRes = let
  val s0 = iand(rs, 15)
  val r0 = iand(ishr(rs, 4), 15)
in
  if ieq(s0, 0) then prog_ac_refine_zero(src, nsrc, bst, sst, data, dbase, bit, se, k, r0)
  else if ine(s0, 1) then @{k= k, ok= false, done= true}
  else let
    val b = get_bit(src, nsrc, bst)
    val s = if ieq(b, 1) then bit else ~bit
    val adv = refine_advance_run(airlock_nat(MAX_REC_FUEL), src, nsrc, bst, data, dbase, bit, s, r0, k, se)
  in @{k= adv.k, ok= true, done= adv.done} end
end

fun prog_ac_refine_loop {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), src: !Buf, nsrc: int, hac: !Buf, ha: int,
  bit: int, se: int, data: !Buf, dbase: int, k: int,
  bst: &JpgBits >> _, sst: &ScanState >> _
): bool =
  if recursion_fuel_available(recfuel) then (
    if igt(k, se) then true
    else let
      val rs = huff_decode(src, nsrc, hac, ha, bst)
    in
      if ilt(rs, 0) then false
      else let
        val res = prog_ac_refine_step(src, nsrc, bst, sst, data, dbase, bit, se, k, rs)
      in
        if not(res.ok) then false
        else if res.done then true
        else prog_ac_refine_loop(recfuel - 1, src, nsrc, hac, ha, bit, se, data, dbase, res.k, bst, sst)
      end
    end
  ) else false

fun decode_prog_ac_first(src: !Buf, nsrc: int, hac: !Buf, fab: !Buf, ha: int, sl: int, se: int, ss: int, data: !Buf, dbase: int, bst: &JpgBits >> _, sst: &ScanState >> _): bool =
  if igt(sst.eob_run, 0) then let
    val () = sst.eob_run := isub(sst.eob_run, 1)
  in true end
  else prog_ac_first_loop(airlock_nat(MAX_REC_FUEL), src, nsrc, hac, fab, ha, sl, se, data, dbase, ss, bst, sst)

fun decode_prog_ac_refine(src: !Buf, nsrc: int, hac: !Buf, ha: int, sl: int, se: int, ss: int, data: !Buf, dbase: int, bst: &JpgBits >> _, sst: &ScanState >> _): bool = let
  val bit = ishl(1, sl)
in
  if igt(sst.eob_run, 0) then let
    val () = sst.eob_run := isub(sst.eob_run, 1)
    val () = refine_block_eob(airlock_nat(MAX_REC_FUEL), src, nsrc, bst, data, dbase, bit, ss, se)
  in true end
  else prog_ac_refine_loop(airlock_nat(MAX_REC_FUEL), src, nsrc, hac, ha, bit, se, data, dbase, ss, bst, sst)
end

fun decode_block_prog_ac(src: !Buf, nsrc: int, meta: !Buf, hac: !Buf, fab: !Buf, c_idx: int, data: !Buf, dbase: int, bst: &JpgBits >> _, sst: &ScanState >> _): bool = let
  val ss = buf_get32(meta, META_SPEC_START)
  val se = buf_get32(meta, META_SPEC_END)
  val sh = buf_get32(meta, META_SUCC_HIGH)
  val sl = buf_get32(meta, META_SUCC_LOW)
  val ha = comp_get(meta, c_idx, COMP_HA)
in
  if ieq(sh, 0) then decode_prog_ac_first(src, nsrc, hac, fab, ha, sl, se, ss, data, dbase, bst, sst)
  else decode_prog_ac_refine(src, nsrc, hac, ha, sl, se, ss, data, dbase, bst, sst)
end

#endif
