fun span_covered(d: !Doc): int =
  span_covered_with_fuel(airlock_nat(MAX_REC_FUEL), d, 0, doc_len(d))

fun mid_bytes(d: !Doc): int =
  (if ieq(doc_len(d), 5) andalso ieq(eqb(d, 0, 97), 1) andalso ieq(eqb(d, 1, 98), 1) andalso ieq(eqb(d, 2, 99), 1) andalso ieq(eqb(d, 3, 101), 1) andalso ieq(eqb(d, 4, 102), 1) andalso ieq(doc_caret(d), 3) then 1 else 0)

fun selftest_delete_mid(): int = let
  val d = doc_open()
  val () = put_str(d, "abcdef")
  val () = doc_left_move(d)
  val () = doc_left_move(d)
  val () = doc_left_move(d)
  val () = doc_delete(d)
  val ok = (if ieq(mid_bytes(d), 1) andalso ieq(span_covered(d), 1) then 1 else 0)
  val () = doc_free(d)
in
  ok
end

fun tail_bytes(d: !Doc): int =
  (if ieq(doc_len(d), 5) andalso ieq(eqb(d, 0, 97), 1) andalso ieq(eqb(d, 1, 98), 1) andalso ieq(eqb(d, 2, 99), 1) andalso ieq(eqb(d, 3, 100), 1) andalso ieq(eqb(d, 4, 101), 1) andalso ieq(doc_caret(d), 5) then 1 else 0)

fun selftest_delete_tail(): int = let
  val d = doc_open()
  val () = put_str(d, "abcdef")
  val () = doc_left_move(d)
  val () = doc_delete(d)
  val ok = (if ieq(tail_bytes(d), 1) andalso ieq(span_covered(d), 1) then 1 else 0)
  val () = doc_free(d)
in
  ok
end

fun utf_bytes(d: !Doc): int =
  (if ieq(doc_len(d), 4) andalso ieq(eqb(d, 0, 97), 1) andalso ieq(eqb(d, 1, 98), 1) andalso ieq(eqb(d, 2, 100), 1) andalso ieq(eqb(d, 3, 101), 1) andalso ieq(doc_caret(d), 2) then 1 else 0)

fun selftest_delete_utf(): int = let
  val d = doc_open()
  val () = put_str(d, "abğde")
  val () = doc_set_caret_move(d, 2)
  val () = doc_delete(d)
  val ok = (if ieq(utf_bytes(d), 1) andalso ieq(span_covered(d), 1) then 1 else 0)
  val () = doc_free(d)
in
  ok
end

fun twice_bytes(d: !Doc): int =
  (if ieq(doc_len(d), 4) andalso ieq(eqb(d, 0, 97), 1) andalso ieq(eqb(d, 1, 98), 1) andalso ieq(eqb(d, 2, 99), 1) andalso ieq(eqb(d, 3, 102), 1) andalso ieq(doc_caret(d), 3) then 1 else 0)

fun selftest_delete_twice(): int = let
  val d = doc_open()
  val () = put_str(d, "abcdef")
  val () = doc_set_caret_move(d, 3)
  val () = doc_delete(d)
  val () = doc_delete(d)
  val ok = (if ieq(twice_bytes(d), 1) andalso ieq(span_covered(d), 1) then 1 else 0)
  val () = doc_free(d)
in
  ok
end

fun selftest_delete_part(): int = let
  val mid = selftest_delete_mid()
  val tail = selftest_delete_tail()
  val utf = selftest_delete_utf()
  val twice = selftest_delete_twice()
  val () = println! ("del_mid=", mid, " del_tail=", tail, " del_utf=", utf, " del_twice=", twice)
in
  (if ieq(mid, 1) andalso ieq(tail, 1) andalso ieq(utf, 1) andalso ieq(twice, 1) then 1 else 0)
end

extern fun find_kind_node_fuel_exhausted(d: !Doc, k: NodeKind, i: int, n: int): int = "mac#anth_die_int"

fun find_kind_node_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, k: NodeKind, i: int, n: int
): int =
  if recfuel > 0 then (
    if i >= n then ~1
    else if is_kind(doc_node_kind(d, i), k) then i
    else find_kind_node_with_fuel(recfuel - 1, d, k, iadd(i, 1), n)
  ) else find_kind_node_fuel_exhausted(d, k, i, n)

fun find_kind_node(d: !Doc, k: NodeKind, i: int): int =
  find_kind_node_with_fuel(airlock_nat(MAX_REC_FUEL), d, k, i, d_nnodes(d))

extern fun find_heading_by_hashes_fuel_exhausted(d: !Doc, hcount: int, i: int, n: int): int = "mac#anth_die_int"

fun find_heading_by_hashes_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, hcount: int, i: int, n: int
): int =
  if recfuel > 0 then (
    if i >= n then ~1
    else let
      val k = doc_node_kind(d, i)
    in
      if is_heading(k) andalso ieq(doc_node_aux(d, i), hcount) then i
      else find_heading_by_hashes_with_fuel(recfuel - 1, d, hcount, iadd(i, 1), n)
    end
  ) else find_heading_by_hashes_fuel_exhausted(d, hcount, i, n)

fun find_heading_by_hashes(d: !Doc, hcount: int, i: int): int =
  find_heading_by_hashes_with_fuel(airlock_nat(MAX_REC_FUEL), d, hcount, i, d_nnodes(d))

fun selftest_check_head_preserve(): int = let
  val d = doc_open()
  val () = put_str(d, "# H1\nText 1\n## H2\nText 2\n### H3\nText 3\n# Next\nEnd\n")
  val _ = doc_layout(d, 18)
  val h2 = find_heading_by_hashes(d, 2, 0)
  val () = doc_toggle(d, h2)
  val _ = doc_layout(d, 18)
  val h2_c1 = doc_node_collapsed(d, h2)
  val h1 = find_heading_by_hashes(d, 1, 0)
  val () = doc_toggle(d, h1)
  val _ = doc_layout(d, 18)
  val h2_c2 = doc_node_collapsed(d, h2)
  val () = doc_toggle(d, h1)
  val _ = doc_layout(d, 18)
  val h2_c3 = doc_node_collapsed(d, h2)
  val ok = is_on(h2_c1) andalso is_on(h2_c2) andalso is_on(h2_c3)
  val () = doc_free(d)
in
  if ok then 1 else 0
end

fun selftest_check_list_leaf(): int = let
  val d = doc_open()
  val () = put_str(d, "- Parent\n  - Child\n- Sibling Leaf\n")
  val _ = doc_layout(d, 18)
  val p_i = find_kind_node(d, KLi, 0)
  val c_i = (if ige(p_i, 0) then find_kind_node(d, KLi, iadd(p_i, 1)) else ~1)
  val s_i = (if ige(c_i, 0) then find_kind_node(d, KLi, iadd(c_i, 1)) else ~1)
  val p_fold = (if ige(p_i, 0) then doc_is_foldable(d, p_i) else false)
  val c_fold = (if ige(c_i, 0) then doc_is_foldable(d, c_i) else false)
  val s_fold = (if ige(s_i, 0) then doc_is_foldable(d, s_i) else false)
  val ok = (if p_fold then (if c_fold then 0 else (if s_fold then 0 else 1)) else 0) : int
  val () = doc_free(d)
in
  ok
end

fun selftest_check_delimited(): int = let
  val d = doc_open()
  val () = put_str(d, "```rust\nfn main() {}\n```\n")
  val _ = doc_layout(d, 18)
  val code_i = find_kind_node(d, KCode, 0)
  val fold_ok = (if ige(code_i, 0) then doc_is_foldable(d, code_i) else false)
  val () = if ige(code_i, 0) then doc_toggle(d, code_i) else ()
  val _ = doc_layout(d, 18)
  val st = (if ige(code_i, 0) then doc_node_start(d, code_i) else 0)
  val first_line_hid = doc_layout_line_hidden(d, st, iadd(st, 5), d_nnodes(d))
  val ok = (if fold_ok then (if ieq(first_line_hid, 0) then 1 else 0) else 0) : int
  val () = doc_free(d)
in
  ok
end

fun selftest_check_deep_toggle(): int = let
  val d = doc_open()
  val () = put_str(d, "# H1\nText 1\n## H2\nText 2\n")
  val _ = doc_layout(d, 18)
  val h1 = find_heading_by_hashes(d, 1, 0)
  val h2 = find_heading_by_hashes(d, 2, 0)
  val () = doc_toggle_deep(d, h1)
  val _ = doc_layout(d, 18)
  val c1_on = is_on(doc_node_collapsed(d, h1))
  val c2_on = is_on(doc_node_collapsed(d, h2))
  val () = doc_toggle_deep(d, h1)
  val _ = doc_layout(d, 18)
  val c1_off = is_off(doc_node_collapsed(d, h1))
  val c2_off = is_off(doc_node_collapsed(d, h2))
  val ok = (if c1_on andalso c2_on andalso c1_off andalso c2_off then 1 else 0) : int
  val () = doc_free(d)
in
  ok
end

fun selftest_check_edit_shift(): int = let
  val d = doc_open()
  val () = put_str(d, "# Top\nTop Content\n## Target\nTarget Body\n")
  val _ = doc_layout(d, 18)
  val h_target = find_heading_by_hashes(d, 2, 0)
  val off_before = (if ige(h_target, 0) then doc_node_start(d, h_target) else 0)
  val () = if ige(h_target, 0) then doc_toggle(d, h_target) else ()
  val has_before = fold_has(d, off_before)
  val () = folds_apply_edit(d, 0, 0, 10)
  val has_after_shifted = fold_has(d, iadd(off_before, 10))
  val ok = (if has_before then (if has_after_shifted then 1 else 0) else 0) : int
  val () = doc_free(d)
in
  ok
end

fun selftest_folding_model(): int = let
  val p_ok = selftest_check_head_preserve()
  val l_ok = selftest_check_list_leaf()
  val d_ok = selftest_check_delimited()
  val dt_ok = selftest_check_deep_toggle()
  val es_ok = selftest_check_edit_shift()
  val () = println! ("fold_preserve=", p_ok, " fold_leaf=", l_ok, " fold_delim=", d_ok, " fold_deep=", dt_ok, " fold_shift=", es_ok)
in
  if ieq(p_ok, 1) andalso ieq(l_ok, 1) andalso ieq(d_ok, 1) andalso ieq(dt_ok, 1) andalso ieq(es_ok, 1) then 1 else 0
end

