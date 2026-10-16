implement doc_selftest() = let
  val d = doc_open()
  val a_ok = selftest_markdown_part(d)
  val b_ok = selftest_layout_part(d)
  val c_ok = selftest_history_part()
  val () = selftest_big_part()
  val v_ok = selftest_vfs_part()
  val d_ok = selftest_delete_part()
  val f_ok = selftest_folding_model()
  val t_ok = ast_selftest()
  val () = doc_free(d)
in
  (if ieq(a_ok, 1) andalso ieq(b_ok, 1) andalso ieq(c_ok, 1) andalso ieq(v_ok, 1) andalso ieq(d_ok, 1) andalso ieq(f_ok, 1) andalso ieq(t_ok, 1) then 1 else 0)
end

extern fun line_node_foldable_fuel_exhausted(d: !Doc, line: int, i: int, n: int): int = "mac#anth_die_int"

fun line_node_foldable_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, line: int, i: int, n: int
): int =
  if recfuel > 0 then (
    if i >= n then ~1
    else let
      val st = doc_node_start(d, i)
      val l = doc_line_of(d, st)
    in
      if ieq(l, line) andalso doc_is_foldable(d, i) then i
      else line_node_foldable_with_fuel(recfuel - 1, d, line, iadd(i, 1), n)
    end
  ) else line_node_foldable_fuel_exhausted(d, line, i, n)

fun line_node_foldable(d: !Doc, line: int): int =
  line_node_foldable_with_fuel(airlock_nat(MAX_REC_FUEL), d, line, 0, d_nnodes(d))

implement doc_line_node_foldable(d, line) =
  line_node_foldable(d, line)

fun dump_one_line(d: !Doc, line: int): void = let
  val st = doc_line_start(d, line)
  val step = doc_line_step(d, line)
  val ni = line_node_foldable(d, line)
  val is_f = (if ige(ni, 0) then 1 else 0) : int
  val fend = (if ige(ni, 0) then doc_node_fold_end(d, ni) else 0) : int
in
  println! ("L", line, ": st=", st, " step=", step, " fold=", is_f, " end=", fend)
end

extern fun dump_lines_m_fuel_exhausted(d: !Doc, line: int, n: int): void = "mac#anth_die_void"

fun dump_lines_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, line: int, n: int
): void =
  if recfuel > 0 then (
    if ige(line, n) then ()
    else let
      val () = dump_one_line(d, line)
    in
      dump_lines_with_fuel(recfuel - 1, d, iadd(line, 1), n)
    end
  ) else dump_lines_m_fuel_exhausted(d, line, n)

fun test_toggle_one(d: !Doc, line: int): void = let
  val ni = line_node_foldable(d, line)
in
  if ige(ni, 0) then let
    val () = println! ("--- TEST TOGGLE LINE ", line, " ---")
    val () = doc_toggle(d, ni)
    val _ = doc_layout(d, 18)
    val () = println! ("After fold: L", line, " coll=", toggle_int(doc_node_collapsed(d, ni)))
    val () = dump_one_line(d, line)
    val () = dump_one_line(d, iadd(line, 1))
    val () = doc_toggle(d, ni)
    val _ = doc_layout(d, 18)
    val () = println! ("After unfold: L", line, " coll=", toggle_int(doc_node_collapsed(d, ni)))
    val () = dump_one_line(d, line)
    val () = dump_one_line(d, iadd(line, 1))
  in
  end else ()
end

extern fun test_toggles_m_fuel_exhausted(d: !Doc, line: int, n: int): void = "mac#anth_die_void"

fun test_toggles_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, line: int, n: int
): void =
  if recfuel > 0 then (
    if ige(line, n) then ()
    else let
      val () = test_toggle_one(d, line)
    in
      test_toggles_with_fuel(recfuel - 1, d, iadd(line, 1), n)
    end
  ) else test_toggles_m_fuel_exhausted(d, line, n)

fun test_hierarchy(d: !Doc): void = let
  val n8 = line_node_foldable(d, 8)
  val n10 = line_node_foldable(d, 10)
in
  if ige(n8, 0) andalso ige(n10, 0) then let
    val () = println! ("=== TEST HIERARCHY (H1 and H2) ===")
    val () = doc_toggle(d, n10)
    val _ = doc_layout(d, 18)
    val () = println! ("Step 1 (H2 folded): L10 coll=", toggle_int(doc_node_collapsed(d, n10)), " L11 step=", doc_line_step(d, 11))
    val () = doc_toggle(d, n8)
    val _ = doc_layout(d, 18)
    val () = println! ("Step 2 (H1 folded): L8 coll=", toggle_int(doc_node_collapsed(d, n8)), " L9 step=", doc_line_step(d, 9), " L10 step=", doc_line_step(d, 10))
    val () = doc_toggle(d, n8)
    val _ = doc_layout(d, 18)
    val () = println! ("Step 3 (H1 unfolded): L8 coll=", toggle_int(doc_node_collapsed(d, n8)), " L9 step=", doc_line_step(d, 9), " L10 coll=", toggle_int(doc_node_collapsed(d, n10)), " L11 step=", doc_line_step(d, 11))
    val () = doc_toggle(d, n10)
    val _ = doc_layout(d, 18)
    val () = println! ("Step 4 (H2 unfolded): L10 coll=", toggle_int(doc_node_collapsed(d, n10)), " L11 step=", doc_line_step(d, 11))
  in
  end else ()
end

implement doc_fold_dump(path) = let
  val d = doc_open()
  val ok = doc_load(d, path)
in
  if not(ok) then let
    val () = println! ("fold_dump: cannot open ", path)
    val () = doc_free(d)
  in
  end else let
    val _ = doc_layout(d, 18)
    val () = println! ("=== FOLD DUMP: ", path, " lines=", doc_nlines(d), " nodes=", d_nnodes(d), " ===")
    val () = dump_lines_with_fuel(airlock_nat(MAX_REC_FUEL), d, 0, doc_nlines(d))
    val () = test_toggles_with_fuel(airlock_nat(MAX_REC_FUEL), d, 0, doc_nlines(d))
    val () = test_hierarchy(d)
    val () = doc_free(d)
  in
  end
end
