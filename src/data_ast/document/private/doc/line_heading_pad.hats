fun line_heading_pad(d: !Doc, st: int, en: int, i: int, n: int, lh: int): int =
  line_heading_pad_with_fuel(airlock_nat(MAX_REC_FUEL), d, st, en, i, n, lh, 0)

implement doc_layout_heading_padding(d, start, stop, node_count, line_height) =
  line_heading_pad(d, start, stop, 0, node_count, line_height)

fun reparse(d: !Doc, at: int, oldlen: int): void = let
  val curlen = d_len(d)
  val delta = isub(curlen, oldlen)
  val del_bytes = (if ilt(delta, 0) then isub(0, delta) else 0)
  val ins_bytes = (if igt(delta, 0) then delta else 0)
  val () = lines_apply_edit(d, at, del_bytes, ins_bytes)
  val () = folds_apply_edit(d, at, del_bytes, ins_bytes)
  val () = ast_reparse_v2(d, at, del_bytes, ins_bytes)
  val () = doc_compute_foldability(d)
in
  fold_apply(d)
end

extern fun gap_put_fuel_exhausted(d: !Doc, p: ptr, n: int, lo: int, i: int): void = "mac#anth_die_void"

fun gap_put_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, p: ptr, n: int, lo: int, i: int): void =
  if recursion_fuel_available(recfuel) then (
    if i < n then let
      val () = gap_set(d, iadd(lo, i), mem_byte(p, n, i))
    in
      gap_put_with_fuel(recfuel - 1, d, p, n, lo, iadd(i, 1))
    end else ()
  ) else gap_put_fuel_exhausted(d, p, n, lo, i)

fun gap_put(d: !Doc, p: ptr, n: int): void = let
  val () = gap_room(d, n)
  val lo = d_lo(d)
  val () = gap_put_with_fuel(airlock_nat(MAX_REC_FUEL), d, p, n, lo, 0)
in
  d_set_lo(d, iadd(lo, n));
  d_set_len(d, iadd(d_len(d), n))
end

fun sel_span(d: !Doc, a: &int >> _, b: &int >> _): void = let
  val c = d_caret(d)
  val k = d_anchor(d)
in
  if c < k then (a := c; b := k) else (a := k; b := c)
end

fun remove_between(d: !Doc, a0: int, b0: int): void = let
  val len = d_len(d)
  val a = if a0 < 0 then 0 else a0
  val b = if b0 > len then len else b0
in
  if ile(b, a) then ()
  else let
    val old = d_len(d)
    val () = gap_move(d, a)
    val hi = d_hi(d)
    val () = d_set_hi(d, iadd(hi, isub(b, a)))
    val () = d_set_len(d, isub(len, isub(b, a)))
    val () = d_set_caret(d, a)
    val () = d_set_anchor(d, a)
    val () = d_bump_ver(d)
    val () = fold_shift(d, a, isub(a, b))
  in
    reparse(d, a, old)
  end
end

fun doc_gap_copy_to_ptr(d: !Doc, src_off: int, dst: ptr, dst_cap: int, dst_off: int, n: int): void =
  case+ d of
  | @DOC(s) => let
      val () = buf_copy_to_ptr(s.gap, src_off, dst, dst_cap, dst_off, n)
    in
      fold@(d)
    end

fun doc_gap_copy_to_buf(d: !Doc, src_off: int, dst: !Buf, dst_off: int, n: int): void =
  case+ d of
  | @DOC(s) => let
      val () = buf_copy_range(dst, dst_off, s.gap, src_off, n)
    in
      fold@(d)
    end

fun doc_slice_calc(d: !Doc, a: int, n: int, dst: ptr, cap: int): void = let
  val lo = d_lo(d)
  val hi = d_hi(d)
in
  if ilt(a, lo) then let
    val l1 = imin(n, isub(lo, a))
    val () = doc_gap_copy_to_ptr(d, a, dst, cap, 0, l1)
    val () = if igt(n, l1) then let
      val l2 = isub(n, l1)
      val () = doc_gap_copy_to_ptr(d, hi, dst, cap, l1, l2)
    in
    end else ()
  in
  end else let
    val s2 = iadd(hi, isub(a, lo))
    val () = doc_gap_copy_to_ptr(d, s2, dst, cap, 0, n)
  in
  end
end

implement doc_slice(d, a0, b0, dst, cap) = let
  val len = d_len(d)
  val a = if a0 < 0 then 0 else a0
  val b = if b0 > len then len else b0
  val n = if igt(isub(b, a), cap) then cap else isub(b, a)
  val () = if igt(n, 0) then doc_slice_calc(d, a, n, dst, cap) else ()
in
  n
end

implement doc_slice_buf(d, a, b, dst, cap) =
  doc_slice(d, a, b, buf_ptr(dst), cap)

implement doc_text(d, dst) = let
  val n = d_len(d)
  val () = buf_resize(dst, iadd(n, 1))
  val lo = d_lo(d)
  val hi = d_hi(d)
  val () = if igt(lo, 0) then doc_gap_copy_to_buf(d, 0, dst, 0, lo) else ()
  val tail = isub(n, lo)
  val () = if igt(tail, 0) then doc_gap_copy_to_buf(d, hi, dst, lo, tail) else ()
  val () = buf_set(dst, n, 0)
in
  buf_set_len(dst, n)
end

fun doc_snapshot_curr(d: !Doc): Buf = let
  var b = buf_make(iadd(doc_len(d), 1))
  val () = doc_text(d, b)
in
  b
end

fun get_last_op(d: !Doc): EditOp =
  case+ d of
  | @DOC(s) => let
      val o = s.last_op
    in
      fold@(d); o
    end

fun get_typing_cnt(d: !Doc): int =
  case+ d of
  | @DOC(s) => let
      val c = s.typing_cnt
    in
      fold@(d); c
    end

fun set_typing_cnt(d: !Doc, c: int): void =
  case+ d of
  | @DOC(s) => let
      val () = s.typing_cnt := c
    in
      fold@(d)
    end

fun set_last_op_and_reset_count(d: !Doc, opk: EditOp): void =
  case+ d of
  | @DOC(s) => let
      val () = s.last_op := opk
      val () = s.typing_cnt := 0
    in
      fold@(d)
    end

fun push_undo_current(d: !Doc): void = let
  val snap = doc_snapshot_curr(d)
  val cur_c = doc_caret(d)
  var u = take_uhist(d)
  val u2 = hist_trim(u)
  val u3 = HCons(snap, cur_c, u2)
in
  put_uhist(d, u3)
end

fun push_redo_current(d: !Doc): void = let
  val cur_snap = doc_snapshot_curr(d)
  val cur_c = doc_caret(d)
  var r = take_rhist(d)
  val r2 = hist_trim(r)
  val r3 = HCons(cur_snap, cur_c, r2)
in
  put_rhist(d, r3)
end

fun doc_record(d: !Doc, opk: EditOp): void = let
  val lo = get_last_op(d)
  val tc = get_typing_cnt(d)
in
  if is_op(opk, OpChar) andalso is_op(lo, OpChar) andalso ilt(tc, 8) then set_typing_cnt(d, iadd(tc, 1))
  else let
    val () = push_undo_current(d)
    val () = put_rhist(d, HNil())
    val () = set_last_op_and_reset_count(d, opk)
  in
  end
end
