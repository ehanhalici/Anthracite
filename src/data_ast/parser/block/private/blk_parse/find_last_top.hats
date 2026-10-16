fun find_last_top(d: !Doc, from_i: int, to_i: int, default_val: int): int =
  find_last_top_with_fuel(airlock_nat(MAX_REC_FUEL), d, from_i, to_i, default_val)

extern fun find_top_fuel_exhausted(d: !Doc, off: int, cur: int, prev: int, p_top: &int >> _, c_top: &int >> _): void = "mac#anth_die_void"

fun find_top_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, off: int, cur: int, prev: int,
  p_top: &int >> _, c_top: &int >> _
): void =
  if recursion_fuel_available(recfuel) then (
    if ige(cur, doc_nnodes(d)) then (p_top := prev; c_top := ~1)
    else let
      val st = doc_node_start(d, cur)
      val en = doc_node_end(d, cur)
      val sub = doc_node_subend(d, cur)
      val next_cur = (if igt(sub, cur) then sub else iadd(cur, 1))
    in
      if ige(off, st) andalso ile(off, en) then (p_top := prev; c_top := cur)
      else if ilt(off, st) then (p_top := prev; c_top := cur)
      else find_top_with_fuel(recfuel - 1, d, off, next_cur, cur, p_top, c_top)
    end
  ) else find_top_fuel_exhausted(d, off, cur, prev, p_top, c_top)

extern fun collect_res_fuel_exhausted(d: !Doc, resync: &Buf >> _, min_st: int, cur: int, count: int): int = "mac#anth_die_int"

fun collect_res_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, resync: &Buf >> _, min_st: int, cur: int, count: int
): int =
  if recursion_fuel_available(recfuel) then (
    if ige(cur, doc_nnodes(d)) then count
    else let
      val st = doc_node_start(d, cur)
      val sub = doc_node_subend(d, cur)
      val next_cur = (if igt(sub, cur) then sub else iadd(cur, 1))
    in
      if ige(st, min_st) then let
        val () = buf_push32(resync, st)
        val () = buf_push32(resync, cur)
      in
        collect_res_with_fuel(recfuel - 1, d, resync, min_st, next_cur, iadd(count, 1))
      end else collect_res_with_fuel(recfuel - 1, d, resync, min_st, next_cur, count)
    end
  ) else collect_res_fuel_exhausted(d, resync, min_st, cur, count)

fun reparse_splice(
  d: !Doc, old_b: !Buf, p_top: int, head_end: int, old_total: int,
  delta: int, matched_old: int
): void = let
  val first_new_top = head_end
  val new_end = doc_nnodes(d)
  val last_new_top = find_last_top(d, head_end, new_end, ~1)
in
  if matched_old >= 0 andalso ilt(matched_old, old_total) then let
    val new_tail_idx = doc_nnodes(d)
    val idxdelta = isub(new_tail_idx, matched_old)
    val () = copy_tail_nodes_with_fuel(airlock_nat(MAX_REC_FUEL), d, old_b, matched_old, old_total, delta, idxdelta)
    val () = if ige(last_new_top, 0) then doc_set(d, last_new_top, NF_NEXT_SIB, new_tail_idx) else ()
    val () = if igt(head_end, 0) andalso ige(p_top, 0) then doc_set(d, p_top, NF_NEXT_SIB, first_new_top) else ()
  in
  end else (
    if igt(head_end, 0) andalso ige(p_top, 0) then doc_set(d, p_top, NF_NEXT_SIB, first_new_top) else ()
  )
end

fun ast_reparse_do(
  d: !Doc, at: int, oldlen: int, newlen: int, delta: int, old_total: int, p_top: int, c_top: int
): void = let
  val at_ls = doc_line_start(d, doc_line_of(d, at))
  val c_st = (if c_top >= 0 then doc_node_start(d, c_top) else at_ls)
  val P0 = imin(at_ls, c_st)
  val head_end = (if c_top >= 0 then c_top else 0)
  var resync = buf_make(AST_REPARSE_DO_RESYNC_INITIAL_BYTES)
  val nres = collect_res_with_fuel(airlock_nat(MAX_REC_FUEL), d, resync, iadd(at, oldlen), 0, 0)
  var old_b = buf_make(imul(old_total, 64))
  val () = save_old_nodes_with_fuel(airlock_nat(MAX_REC_FUEL), d, old_b, 0, old_total)
  val () = doc_clear_nodes(d)
  val () = copy_head_nodes_with_fuel(airlock_nat(MAX_REC_FUEL), d, old_b, 0, head_end)
  var stk = buf_make(imul(64, 20))
  var matched_old: int = ~1
  val q = blk_parse_until(d, P0, resync, nres, delta, iadd(at, newlen), stk, matched_old)
  val () = reparse_splice(d, old_b, p_top, head_end, old_total, delta, matched_old)
  val () = doc_set_span(d, isub(q, P0))
  val () = buf_free(stk)
  val () = buf_free(old_b)
  val () = buf_free(resync)
in
end

implement ast_reparse_v2(d, at, oldlen, newlen) = let
  val is_md = doc_is_md(d)
in
  if is_off(is_md) then (doc_clear_nodes(d); doc_set_span(d, 0))
  else let
    val old_total = doc_nnodes(d)
  in
    if ile(old_total, 0) then ast_parse_all(d)
    else let
      var p_top: int = ~1
      var c_top: int = ~1
      val () = find_top_with_fuel(airlock_nat(MAX_REC_FUEL), d, at, 0, ~1, p_top, c_top)
    in
      if ilt(c_top, 0) then ast_parse_all(d)
      else ast_reparse_do(d, at, oldlen, newlen, isub(newlen, oldlen), old_total, p_top, c_top)
    end
  end
end
