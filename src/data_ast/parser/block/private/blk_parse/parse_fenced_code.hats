fun parse_fenced_code(
  d: !Doc, stk: &Buf >> _, ls: int, le: int, p: int, ch: int, flen: int, ln_end: int,
  next_pos: &int >> _
): void = let
  var c_st: int = ~1
  var c_en: int = ~1
  val found = find_close_fence_with_fuel(airlock_nat(MAX_REC_FUEL), d, ln_end, doc_len(d), ch, flen, c_st, c_en)
  val code_end = (if found then c_en else doc_len(d))
  val f_t = (if ieq(ch, CHAR_TILDE) then FL_TILDE else 0)
  val f_c = (if found then FL_CLOSED else FL_ERROR)
  val c_node = add_child_node(d, stk, KCode, ls, code_end, flen, iadd(f_t, f_c))
in
  if ige(c_node, 0) then (
    code_add_children(d, c_node, p, flen, le, ln_end, found, c_st, c_en, code_end);
    next_pos := (if found then line_next(d, c_st) else doc_len(d))
  ) else ()
end

fun parse_hr(d: !Doc, stk: &Buf >> _, ls: int, le: int): void = let
  val _ = add_child_node(d, stk, KHr, ls, le, 0, 0)
in
end

fun parse_para_line(d: !Doc, stk: &Buf >> _, ls: int, le: int): void = let
  val p_node = add_child_node(d, stk, KPara, ls, le, 0, 0)
in
  if ige(p_node, 0) then let
    var sib: int = ~1
    val () = inl_parse_depth(d, p_node, ls, le, 0, sib)
    val () = doc_node_close(d, p_node, le, ls, le)
  in
  end else ()
end

fun parse_quote(
  d: !Doc, stk: &Buf >> _, ls: int, le: int, p: int
): void = let
  val q_node = add_child_node(d, stk, KQuote, ls, le, 0, 0)
in
  if ige(q_node, 0) then let
    val content_st = (if ilt(iadd(p, 1), le) andalso ieq(doc_byte(d, iadd(p, 1)), CHAR_SPACE) then iadd(p, 2) else iadd(p, 1))
    val p_child = doc_node_add(d, KPara, content_st, le, q_node, ~1, 0, 0)
    val () = if ige(p_child, 0) then let
      var sib: int = ~1
      val () = inl_parse_depth(d, p_child, content_st, le, 0, sib)
      val () = doc_node_close(d, p_child, le, content_st, le)
    in
    end else ()
    val () = doc_node_close(d, q_node, le, content_st, le)
  in
  end else ()
end

extern fun parse_callout_name_fuel_exhausted(d: !Doc, p: int, le: int): int = "mac#anth_die_int"

fun parse_callout_name_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, le: int
): int =
  if recursion_fuel_available(recfuel) then (
    if ige(p, le) then p
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, CHAR_RBRACKET) orelse ieq(b, CHAR_SPACE) orelse ieq(b, CHAR_TAB) then p
      else parse_callout_name_with_fuel(recfuel - 1, d, iadd(p, 1), le)
    end
  ) else parse_callout_name_fuel_exhausted(d, p, le)

fun is_callout_head(d: !Doc, p: int, le: int): bool =
  if ilt(iadd(p, 3), le) andalso ieq(doc_byte(d, p), CHAR_LBRACKET) andalso ieq(doc_byte(d, iadd(p, 1)), CHAR_EXCL) then true
  else false

fun callout_fold_check(d: !Doc, le: int, type_en: int, fold_aux: &int >> _, mark_end: &int >> _): void =
  if ilt(type_en, le) andalso ieq(doc_byte(d, type_en), CHAR_RBRACKET) then let
    val next_i = iadd(type_en, 1)
  in
    if ilt(next_i, le) andalso ieq(doc_byte(d, next_i), CHAR_MINUS) then (
      fold_aux := 2; mark_end := iadd(type_en, 2)
    ) else if ilt(next_i, le) andalso ieq(doc_byte(d, next_i), CHAR_PLUS) then (
      fold_aux := 1; mark_end := iadd(type_en, 2)
    ) else (
      fold_aux := 0; mark_end := next_i
    )
  end else mark_end := type_en

fun callout_add_head(d: !Doc, c_node: int, p: int, le: int, t_st: int, t_en: int, m2_en: int): int = let
  val head = doc_node_add(d, KCalloutHead, p, le, c_node, ~1, 0, 0)
  val m1 = doc_node_add(d, KMark, p, t_st, head, ~1, 0, 0)
  val info = doc_node_add(d, KInfo, t_st, t_en, head, m1, 0, 0)
  val m2 = doc_node_add(d, KMark, t_en, m2_en, head, info, 0, 0)
  val () = if ilt(m2_en, le) then let
    var sib: int = m2
    val () = inl_parse_depth(d, head, m2_en, le, 0, sib)
  in
  end else ()
  val () = doc_node_close(d, head, le, m2_en, le)
in
  head
end

fun callout_add_body(d: !Doc, c_node: int, head: int, ln2_st: int, ln2_le: int): void =
  if igt(ln2_le, 0) then let
    val body_p = doc_node_add(d, KPara, ln2_st, ln2_le, c_node, head, 0, 0)
    val () = if ige(body_p, 0) then let
      var sib: int = ~1
      val () = inl_parse_depth(d, body_p, ln2_st, ln2_le, 0, sib)
      val () = doc_node_close(d, body_p, ln2_le, ln2_st, ln2_le)
    in
    end else ()
  in
  end else ()

fun parse_callout_block(
  d: !Doc, stk: &Buf >> _, ls: int, le: int, p: int, ln2_st: int, ln2_le: int,
  next_pos: &int >> _
): void = let
  val type_st = iadd(p, 2)
  val type_en = parse_callout_name_with_fuel(airlock_nat(MAX_REC_FUEL), d, type_st, le)
  var fold_aux: int = 0
  var mark_end: int = type_en
  val () = callout_fold_check(d, le, type_en, fold_aux, mark_end)
  val mark2_en = (if ilt(mark_end, le) andalso is_space_or_tab(doc_byte(d, mark_end)) then iadd(mark_end, 1) else mark_end)
  val callout_end = (if igt(ln2_le, 0) then ln2_le else le)
  val c_node = add_child_node(d, stk, KCallout, ls, callout_end, fold_aux, 0)
in
  if ige(c_node, 0) then let
    val head = callout_add_head(d, c_node, p, le, type_st, type_en, mark2_en)
    val () = callout_add_body(d, c_node, head, ln2_st, ln2_le)
    val () = doc_node_close(d, c_node, callout_end, p, callout_end)
    val () = next_pos := (if igt(ln2_le, 0) then line_next(d, ln2_st) else line_next(d, ls))
  in
  end else ()
end

fun is_task_box(d: !Doc, p: int, le: int): bool =
  ilt(iadd(p, 3), le) andalso ieq(doc_byte(d, p), CHAR_LBRACKET) andalso ieq(doc_byte(d, iadd(p, 2)), CHAR_RBRACKET) andalso ieq(doc_byte(d, iadd(p, 3)), CHAR_SPACE)

fun list_item_add_children(d: !Doc, li: int, p: int, le: int): void = let
  val m1 = doc_node_add(d, KMark, p, iadd(p, 2), li, ~1, 0, 0)
  val p_st = iadd(p, 2)
  val has_task = is_task_box(d, p_st, le)
  val task_node = (if has_task then doc_node_add(d, KTask, p_st, iadd(p_st, 4), li, m1, 0, 0) else ~1)
  val last_s = (if has_task then task_node else m1)
  val content_st = (if has_task then iadd(p_st, 4) else p_st)
  val para = doc_node_add(d, KPara, content_st, le, li, last_s, 0, 0)
  val () = if ige(para, 0) then let
    var sib: int = ~1
    val () = inl_parse_depth(d, para, content_st, le, 0, sib)
    val () = doc_node_close(d, para, le, content_st, le)
  in
  end else ()
  val () = doc_node_close(d, li, le, content_st, le)
in
end

fun parse_list_item(
  d: !Doc, stk: &Buf >> _, ls: int, le: int, p: int
): void = let
  val ul = add_child_node(d, stk, KUl, ls, le, 0, 0)
in
  if ige(ul, 0) then let
    val li = doc_node_add(d, KLi, ls, le, ul, ~1, 0, 0)
    val () = list_item_add_children(d, li, p, le)
    val () = doc_node_close(d, ul, le, ls, le)
  in
  end else ()
end

fun parse_table_delim(
  d: !Doc, parent: int, prev: int, ls: int, le: int
): int =
  doc_node_add(d, KTableDelim, ls, le, parent, prev, 0, 0)

extern fun parse_table_cells_fuel_exhausted(d: !Doc, row: int, p: int, le: int, prev: int, col: int): void = "mac#anth_die_void"

fun parse_table_cells_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, row: int, p: int, le: int, prev: int, col: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ige(p, le) then ()
    else if ieq(doc_byte(d, p), CHAR_PIPE) then let
      val m = doc_node_add(d, KMark, p, iadd(p, 1), row, prev, 0, 0)
      val cell_st = iadd(p, 1)
      val pipe_pos = find_next_pipe(d, cell_st, le)
      val cell_en = (if ige(pipe_pos, 0) then pipe_pos else le)
    in
      if igt(cell_en, cell_st) then let
        val cell = doc_node_add(d, KTableCell, cell_st, cell_en, row, m, col, 0)
        var sib: int = ~1
        val () = inl_parse_depth(d, cell, cell_st, cell_en, 0, sib)
        val () = doc_node_close(d, cell, cell_en, cell_st, cell_en)
      in
        parse_table_cells_with_fuel(recfuel - 1, d, row, cell_en, le, cell, iadd(col, 1))
      end else parse_table_cells_with_fuel(recfuel - 1, d, row, cell_en, le, m, col)
    end else ()
  ) else parse_table_cells_fuel_exhausted(d, row, p, le, prev, col)

and find_next_pipe(d: !Doc, p: int, le: int): int =
  if ige(p, le) then ~1
  else if ieq(doc_byte(d, p), CHAR_PIPE) then p
  else find_next_pipe(d, iadd(p, 1), le)
