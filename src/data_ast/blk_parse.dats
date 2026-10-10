#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "data_ast/ast.sats"
staload "data_ast/doc.sats"
staload "data_ast/blk_parse.sats"
staload "data_ast/inl_parse.sats"

extern fun line_end_exh(d: !Doc, p: int, len: int): int = "mac#anth_die_int"

fun line_end_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, len: int
): int =
  if recfuel > 0 then (
    if ige(p, len) then p
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, 10) then (
        if igt(p, 0) andalso ieq(doc_byte(d, isub(p, 1)), 13) then isub(p, 1) else p
      ) else line_end_m(recfuel - 1, d, iadd(p, 1), len)
    end
  ) else line_end_exh(d, p, len)

implement line_end(d, ls) =
  line_end_m(airlock_nat(MAX_REC_FUEL), d, ls, doc_len(d))

extern fun line_next_exh(d: !Doc, p: int, len: int): int = "mac#anth_die_int"

fun line_next_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, len: int
): int =
  if recfuel > 0 then (
    if ige(p, len) then p
    else if ieq(doc_byte(d, p), 10) then iadd(p, 1)
    else line_next_m(recfuel - 1, d, iadd(p, 1), len)
  ) else line_next_exh(d, p, len)

implement line_next(d, ls) =
  line_next_m(airlock_nat(MAX_REC_FUEL), d, ls, doc_len(d))

extern fun indent_cols_exh(d: !Doc, p: int, le: int, c: int): void = "mac#anth_die_void"

fun indent_cols_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, le: int, c: int,
  cols: &int >> _, next_p: &int >> _
): void =
  if recfuel > 0 then (
    if ige(p, le) then (cols := c; next_p := p)
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, 32) then indent_cols_m(recfuel - 1, d, iadd(p, 1), le, iadd(c, 1), cols, next_p)
      else if ieq(b, 9) then let
        val next_c = imul(iadd(idiv(c, 4), 1), 4)
      in
        indent_cols_m(recfuel - 1, d, iadd(p, 1), le, next_c, cols, next_p)
      end else (cols := c; next_p := p)
    end
  ) else indent_cols_exh(d, p, le, c)

implement indent_cols(d, p, le, cols, next_p) =
  indent_cols_m(airlock_nat(MAX_REC_FUEL), d, p, le, 0, cols, next_p)

extern fun is_blank_exh(d: !Doc, p: int, le: int): bool = "mac#anth_die_int"

fun is_blank_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, le: int
): bool =
  if recfuel > 0 then (
    if ige(p, le) then true
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, 32) orelse ieq(b, 9) then is_blank_m(recfuel - 1, d, iadd(p, 1), le)
      else false
    end
  ) else is_blank_exh(d, p, le)

implement is_blank(d, p, le) =
  is_blank_m(airlock_nat(MAX_REC_FUEL), d, p, le)

fun stk_depth(stk: !Buf): int = idiv(buf_len(stk), 20)

fun stk_get(stk: !Buf, frame: int, fld: int): int =
  buf_get32(stk, iadd(imul(frame, 20), imul(fld, 4)))

fun stk_set(stk: !Buf, frame: int, fld: int, v: int): void =
  buf_set32(stk, iadd(imul(frame, 20), imul(fld, 4)), v)

fun stk_push(stk: &Buf >> _, node: int, kind: int, ind: int, flags: int): void = let
  val len = buf_len(stk)
  val () = buf_resize(stk, iadd(len, 20))
  val () = buf_set32(stk, len, node)
  val () = buf_set32(stk, iadd(len, 4), ~1)
  val () = buf_set32(stk, iadd(len, 8), kind)
  val () = buf_set32(stk, iadd(len, 12), ind)
  val () = buf_set32(stk, iadd(len, 16), flags)
in
end

fun stk_pop(stk: &Buf >> _): void = let
  val len = buf_len(stk)
in
  if ige(len, 20) then buf_resize(stk, isub(len, 20)) else ()
end

fun stk_top_node(stk: !Buf): int = let
  val d = stk_depth(stk)
in
  if igt(d, 0) then stk_get(stk, isub(d, 1), 0) else ~1
end

fun stk_top_last_child(stk: !Buf): int = let
  val d = stk_depth(stk)
in
  if igt(d, 0) then stk_get(stk, isub(d, 1), 1) else ~1
end

fun stk_set_top_last_child(stk: !Buf, c: int): void = let
  val d = stk_depth(stk)
in
  if igt(d, 0) then stk_set(stk, isub(d, 1), 1, c) else ()
end

fun add_child_node(
  d: !Doc, stk: &Buf >> _, kind: NodeKind, st: int, en: int, aux: int, flags: int
): int = let
  val parent = stk_top_node(stk)
  val prev_sib = stk_top_last_child(stk)
  val idx = doc_node_add(d, kind, st, en, parent, prev_sib, aux, flags)
  val () = if ige(idx, 0) then stk_set_top_last_child(stk, idx) else ()
in
  idx
end

extern fun count_char_exh(d: !Doc, p: int, le: int, ch: int, c: int): int = "mac#anth_die_int"

fun count_char_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, le: int, ch: int, c: int
): int =
  if recfuel > 0 then (
    if ige(p, le) then c
    else if ieq(doc_byte(d, p), ch) then count_char_m(recfuel - 1, d, iadd(p, 1), le, ch, iadd(c, 1))
    else c
  ) else count_char_exh(d, p, le, ch, c)

fun count_char(d: !Doc, p: int, le: int, ch: int): int =
  count_char_m(airlock_nat(MAX_REC_FUEL), d, p, le, ch, 0)

fun is_space_or_tab(b: int): bool = ieq(b, 32) orelse ieq(b, 9)

fun parse_atx_heading(
  d: !Doc, stk: &Buf >> _, ls: int, le: int, p: int, hashes: int
): void = let
  val hk = heading_kind(hashes)
  val h_node = add_child_node(d, stk, hk, ls, le, hashes, 0)
in
  if ige(h_node, 0) then let
    val m_en = (if ilt(iadd(p, hashes), le) andalso is_space_or_tab(doc_byte(d, iadd(p, hashes)))
      then iadd(iadd(p, hashes), 1) else iadd(p, hashes))
    val m_node = doc_node_add(d, KMark, p, m_en, h_node, ~1, 0, 0)
    val txt_st = m_en
    val () = if ilt(txt_st, le) then let
      var sib: int = m_node
      val () = inl_parse_depth(d, h_node, txt_st, le, 0, sib)
    in
    end else ()
    val () = doc_node_close(d, h_node, le, txt_st, le)
  in
  end else ()
end

extern fun find_close_fence_exh(d: !Doc, cur: int, len: int, ch: int, flen: int, c_st: &int >> _, c_en: &int >> _): bool = "mac#anth_die_int"

fun find_close_fence_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, cur: int, len: int, ch: int, flen: int,
  c_st: &int >> _, c_en: &int >> _
): bool =
  if recfuel > 0 then (
    if ige(cur, len) then false
    else let
      val le = line_end(d, cur)
      val nxt = line_next(d, cur)
      var cols: int = 0
      var p: int = cur
      val () = indent_cols(d, cur, le, cols, p)
    in
      if ile(cols, 3) andalso ige(count_char(d, p, le, ch), flen) andalso is_blank(d, iadd(p, count_char(d, p, le, ch)), le) then (
        c_st := cur; c_en := le; true
      ) else find_close_fence_m(recfuel - 1, d, nxt, len, ch, flen, c_st, c_en)
    end
  ) else find_close_fence_exh(d, cur, len, ch, flen, c_st, c_en)

fun skip_spaces(d: !Doc, p: int, le: int): int =
  if ige(p, le) then p
  else if is_space_or_tab(doc_byte(d, p)) then skip_spaces(d, iadd(p, 1), le)
  else p

fun find_word_end(d: !Doc, p: int, le: int): int =
  if ige(p, le) then p
  else if is_space_or_tab(doc_byte(d, p)) then p
  else find_word_end(d, iadd(p, 1), le)

fun code_add_children(
  d: !Doc, c_node: int, p: int, flen: int, le: int, ln_end: int,
  found: bool, c_st: int, c_en: int, code_end: int
): void = let
  val m1 = doc_node_add(d, KMark, p, iadd(p, flen), c_node, ~1, 0, 0)
  val info_st = skip_spaces(d, iadd(p, flen), le)
  val info_en = find_word_end(d, info_st, le)
  val m_last = (if igt(info_en, info_st) then doc_node_add(d, KInfo, info_st, info_en, c_node, m1, 0, 0) else m1)
  val raw_st = ln_end
  val raw_en = (if found andalso igt(c_st, 0) then isub(c_st, 1) else code_end)
  val m_last2 = (if igt(raw_en, raw_st) then doc_node_add(d, KRaw, raw_st, raw_en, c_node, m_last, 0, 0) else m_last)
  val _ = (if found then doc_node_add(d, KMark, c_st, c_en, c_node, m_last2, 0, 0) else ~1)
  val () = doc_node_close(d, c_node, code_end, raw_st, raw_en)
in
end

fun parse_fenced_code(
  d: !Doc, stk: &Buf >> _, ls: int, le: int, p: int, ch: int, flen: int, ln_end: int,
  next_pos: &int >> _
): void = let
  var c_st: int = ~1
  var c_en: int = ~1
  val found = find_close_fence_m(airlock_nat(MAX_REC_FUEL), d, ln_end, doc_len(d), ch, flen, c_st, c_en)
  val code_end = (if found then c_en else doc_len(d))
  val f_t = (if ieq(ch, 126) then FL_TILDE else 0)
  val f_c = (if found then FL_CLOSED else 0)
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
    val content_st = (if ilt(iadd(p, 1), le) andalso ieq(doc_byte(d, iadd(p, 1)), 32) then iadd(p, 2) else iadd(p, 1))
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

extern fun parse_callout_name_exh(d: !Doc, p: int, le: int): int = "mac#anth_die_int"

fun parse_callout_name_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, le: int
): int =
  if recfuel > 0 then (
    if ige(p, le) then p
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, 93) orelse ieq(b, 32) orelse ieq(b, 9) then p
      else parse_callout_name_m(recfuel - 1, d, iadd(p, 1), le)
    end
  ) else parse_callout_name_exh(d, p, le)

fun is_callout_head(d: !Doc, p: int, le: int): bool =
  if ilt(iadd(p, 3), le) andalso ieq(doc_byte(d, p), 91) andalso ieq(doc_byte(d, iadd(p, 1)), 33) then true
  else false

fun callout_fold_check(d: !Doc, le: int, type_en: int, fold_aux: &int >> _, mark_end: &int >> _): void =
  if ilt(type_en, le) andalso ieq(doc_byte(d, type_en), 93) then let
    val next_i = iadd(type_en, 1)
  in
    if ilt(next_i, le) andalso ieq(doc_byte(d, next_i), 45) then (
      fold_aux := 2; mark_end := iadd(type_en, 2)
    ) else if ilt(next_i, le) andalso ieq(doc_byte(d, next_i), 43) then (
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
  val type_en = parse_callout_name_m(airlock_nat(MAX_REC_FUEL), d, type_st, le)
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
  ilt(iadd(p, 3), le) andalso ieq(doc_byte(d, p), 91) andalso ieq(doc_byte(d, iadd(p, 2)), 93) andalso ieq(doc_byte(d, iadd(p, 3)), 32)

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

extern fun parse_table_cells_exh(d: !Doc, row: int, p: int, le: int, prev: int, col: int): void = "mac#anth_die_void"

fun parse_table_cells_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, row: int, p: int, le: int, prev: int, col: int
): void =
  if recfuel > 0 then (
    if ige(p, le) then ()
    else if ieq(doc_byte(d, p), 124) then let
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
        parse_table_cells_m(recfuel - 1, d, row, cell_en, le, cell, iadd(col, 1))
      end else parse_table_cells_m(recfuel - 1, d, row, cell_en, le, m, col)
    end else ()
  ) else parse_table_cells_exh(d, row, p, le, prev, col)

and find_next_pipe(d: !Doc, p: int, le: int): int =
  if ige(p, le) then ~1
  else if ieq(doc_byte(d, p), 124) then p
  else find_next_pipe(d, iadd(p, 1), le)

fun parse_table_row(
  d: !Doc, parent: int, prev: int, ls: int, le: int, is_header: bool
): int = let
  val flg = (if is_header then FL_HEADER_ROW else 0)
  val r_node = doc_node_add(d, KTableRow, ls, le, parent, prev, 0, flg)
in
  if ige(r_node, 0) then let
    val () = parse_table_cells_m(airlock_nat(MAX_REC_FUEL), d, r_node, ls, le, ~1, 0)
    val () = doc_node_close(d, r_node, le, ls, le)
  in
    r_node
  end else ~1
end

fun is_delim_char(b: int): bool =
  ieq(b, 45) orelse ieq(b, 58) orelse ieq(b, 124) orelse ieq(b, 32) orelse ieq(b, 9)

extern fun check_is_delim_exh(d: !Doc, p: int, le: int): bool = "mac#anth_die_int"

fun check_is_delim_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, le: int
): bool =
  if recfuel > 0 then (
    if ige(p, le) then true
    else if is_delim_char(doc_byte(d, p)) then check_is_delim_m(recfuel - 1, d, iadd(p, 1), le)
    else false
  ) else check_is_delim_exh(d, p, le)

fun is_table_delim_line(d: !Doc, p: int, le: int): bool =
  check_is_delim_m(airlock_nat(MAX_REC_FUEL), d, p, le)

fun parse_table_block(
  d: !Doc, stk: &Buf >> _, ls1: int, le1: int, ls2: int, le2: int, ls3: int, le3: int,
  next_pos: &int >> _
): void = let
  val tbl_end = (if igt(le3, 0) then le3 else le2)
  val t_node = add_child_node(d, stk, KTable, ls1, tbl_end, 0, 0)
in
  if ige(t_node, 0) then let
    val r1 = parse_table_row(d, t_node, ~1, ls1, le1, true)
    val d1 = parse_table_delim(d, t_node, r1, ls2, le2)
    val _ = (if igt(le3, 0) then parse_table_row(d, t_node, d1, ls3, le3, false) else ~1)
    val () = doc_node_close(d, t_node, tbl_end, ls1, tbl_end)
    val () = next_pos := (if igt(le3, 0) then line_next(d, ls3) else line_next(d, ls2))
  in
  end else ()
end

fun try_heading(d: !Doc, stk: &Buf >> _, cur: int, le: int, nxt: int, p: int, b: int): int =
  if ieq(b, 35) then let
    val hashes = count_char(d, p, le, 35)
  in
    if ige(hashes, 1) andalso ile(hashes, 6) andalso (
      ige(iadd(p, hashes), le) orelse is_space_or_tab(doc_byte(d, iadd(p, hashes)))
    ) then (parse_atx_heading(d, stk, cur, le, p, hashes); nxt)
    else ~1
  end else ~1

fun try_fence(d: !Doc, stk: &Buf >> _, cur: int, le: int, nxt: int, p: int, b: int): int =
  if (ieq(b, 96) orelse ieq(b, 126)) andalso ige(count_char(d, p, le, b), 3) then let
    var next_p: int = nxt
    val () = parse_fenced_code(d, stk, cur, le, p, b, count_char(d, p, le, b), nxt, next_p)
  in
    next_p
  end else ~1

fun try_quote_callout(d: !Doc, stk: &Buf >> _, cur: int, le: int, nxt: int, len: int, p: int, b: int): int =
  if ieq(b, 62) then let
    val c_st = (if ilt(iadd(p, 1), le) andalso ieq(doc_byte(d, iadd(p, 1)), 32) then iadd(p, 2) else iadd(p, 1))
  in
    if is_callout_head(d, c_st, le) then let
      val nxt_le = (if ilt(nxt, len) then line_end(d, nxt) else ~1)
      val nxt_p = (if ilt(nxt, len) andalso ieq(doc_byte(d, nxt), 62) then (
        if ilt(iadd(nxt, 1), nxt_le) andalso ieq(doc_byte(d, iadd(nxt, 1)), 32) then iadd(nxt, 2) else iadd(nxt, 1)
      ) else ~1)
      var next_pos: int = nxt
      val () = parse_callout_block(d, stk, cur, le, c_st, (if ige(nxt_p, 0) then nxt_p else 0), (if ige(nxt_p, 0) then nxt_le else ~1), next_pos)
    in
      next_pos
    end else (parse_quote(d, stk, cur, le, p); nxt)
  end else ~1

fun try_list_or_table(d: !Doc, stk: &Buf >> _, cur: int, le: int, nxt: int, len: int, p: int, b: int): int =
  if ieq(b, 45) andalso ilt(iadd(p, 1), le) andalso ieq(doc_byte(d, iadd(p, 1)), 32) then (
    parse_list_item(d, stk, cur, le, p); nxt
  ) else if ieq(b, 124) then let
    val l2_st = nxt
    val l2_le = (if ilt(l2_st, len) then line_end(d, l2_st) else ~1)
  in
    if igt(l2_le, 0) andalso is_table_delim_line(d, l2_st, l2_le) then let
      val l3_st = line_next(d, l2_st)
      val l3_le = (if ilt(l3_st, len) then line_end(d, l3_st) else ~1)
      var next_p: int = nxt
      val () = parse_table_block(d, stk, cur, le, l2_st, l2_le, l3_st, l3_le, next_p)
    in
      next_p
    end else ~1
  end else ~1

fun try_hr(d: !Doc, stk: &Buf >> _, cur: int, le: int, nxt: int, p: int, b: int): int =
  if (ieq(b, 45) orelse ieq(b, 42) orelse ieq(b, 95)) andalso ige(count_char(d, p, le, b), 3)
     andalso is_blank(d, iadd(p, count_char(d, p, le, b)), le) then (
    parse_hr(d, stk, cur, le); nxt
  ) else ~1

fun try_frontmatter(d: !Doc, stk: &Buf >> _, cur: int, le: int, nxt: int, len: int): int =
  if ieq(cur, 0) andalso ige(le, 3) andalso ieq(doc_byte(d, 0), 45)
     andalso ieq(doc_byte(d, 1), 45) andalso ieq(doc_byte(d, 2), 45) then let
    var c_st: int = ~1
    var c_en: int = ~1
    val found = find_close_fence_m(airlock_nat(MAX_REC_FUEL), d, nxt, len, 45, 3, c_st, c_en)
  in
    if found then let
      val fm = add_child_node(d, stk, KFm, 0, c_en, 0, 0)
      val () = if ige(fm, 0) then let
        val m1 = doc_node_add(d, KMark, 0, 3, fm, ~1, 0, 0)
        val raw = (if igt(c_st, nxt) then doc_node_add(d, KRaw, nxt, isub(c_st, 1), fm, m1, 0, 0) else m1)
        val _ = doc_node_add(d, KMark, c_st, c_en, fm, raw, 0, 0)
        val () = doc_node_close(d, fm, c_en, nxt, isub(c_st, 1))
      in
      end else ()
    in
      line_next(d, c_st)
    end else ~1
  end else ~1

fun find_fndef_colon_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, le: int
): int =
  if recfuel > 0 then (
    if ige(iadd(p, 1), le) then ~1
    else if ieq(doc_byte(d, p), 93) andalso ieq(doc_byte(d, iadd(p, 1)), 58) then p
    else find_fndef_colon_m(recfuel - 1, d, iadd(p, 1), le)
  ) else ~1

fun try_fndef(d: !Doc, stk: &Buf >> _, cur: int, le: int, nxt: int, p: int, b: int): int =
  if ieq(b, 91) andalso ilt(iadd(p, 1), le) andalso ieq(doc_byte(d, iadd(p, 1)), 94) then let
    val colon = find_fndef_colon_m(airlock_nat(MAX_REC_FUEL), d, iadd(p, 2), le)
  in
    if igt(colon, 0) then let
      val fnd = add_child_node(d, stk, KFndef, cur, le, 0, 0)
      val () = if ige(fnd, 0) then let
        val fn_mark_en = iadd(colon, 2)
        val fn_node = doc_node_add(d, KFn, p, fn_mark_en, fnd, ~1, 0, 0)
        val c_st = (if ilt(fn_mark_en, le) andalso is_space_or_tab(doc_byte(d, fn_mark_en)) then iadd(fn_mark_en, 1) else fn_mark_en)
        val para = doc_node_add(d, KPara, c_st, le, fnd, fn_node, 0, 0)
        val () = if ige(para, 0) then let
          var sib: int = ~1
          val () = inl_parse_depth(d, para, c_st, le, 0, sib)
          val () = doc_node_close(d, para, le, c_st, le)
        in
        end else ()
        val () = doc_node_close(d, fnd, le, c_st, le)
      in
      end else ()
    in
      nxt
    end else ~1
  end else ~1

fun dispatch_line(d: !Doc, stk: &Buf >> _, cur: int, le: int, nxt: int, len: int, p: int): int = let
  val p0 = (if ieq(cur, 0) then try_frontmatter(d, stk, cur, le, nxt, len) else ~1)
in
  if ige(p0, 0) then p0 else let
    val b = doc_byte(d, p)
    val p1 = try_heading(d, stk, cur, le, nxt, p, b)
  in
    if ige(p1, 0) then p1 else let
      val p2 = try_fence(d, stk, cur, le, nxt, p, b)
    in
      if ige(p2, 0) then p2 else let
        val p3 = try_quote_callout(d, stk, cur, le, nxt, len, p, b)
      in
        if ige(p3, 0) then p3 else let
          val p4 = try_list_or_table(d, stk, cur, le, nxt, len, p, b)
        in
          if ige(p4, 0) then p4 else let
            val p5 = try_fndef(d, stk, cur, le, nxt, p, b)
          in
            if ige(p5, 0) then p5 else let
              val p6 = try_hr(d, stk, cur, le, nxt, p, b)
            in
              if ige(p6, 0) then p6 else (parse_para_line(d, stk, cur, le); nxt)
            end
          end
        end
      end
    end
  end
end


extern fun bsearch_resync_exh(resync: !Buf, nres: int, target: int, lo: int, hi: int): int = "mac#anth_die_int"

fun bsearch_resync_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), resync: !Buf, nres: int, target: int, lo: int, hi: int
): int =
  if recfuel > 0 then (
    if igt(lo, hi) then ~1
    else let
      val mid = iadd(lo, idiv(isub(hi, lo), 2))
      val st = buf_get32(resync, imul(mid, 2))
    in
      if ieq(st, target) then buf_get32(resync, iadd(imul(mid, 2), 1))
      else if ilt(st, target) then bsearch_resync_m(recfuel - 1, resync, nres, target, iadd(mid, 1), hi)
      else bsearch_resync_m(recfuel - 1, resync, nres, target, lo, isub(mid, 1))
    end
  ) else bsearch_resync_exh(resync, nres, target, lo, hi)

fun bsearch_resync(resync: !Buf, nres: int, target: int): int =
  if ile(nres, 0) then ~1
  else bsearch_resync_m(airlock_nat(MAX_REC_FUEL), resync, nres, target, 0, isub(nres, 1))

extern fun parse_lines_exh(d: !Doc, cur: int, len: int, stk: &Buf >> _): int = "mac#anth_die_int"

fun check_resync_hit(resync: !Buf, nres: int, cur: int, minpos: int, delta: int): int =
  if igt(nres, 0) andalso ige(cur, minpos) then bsearch_resync(resync, nres, isub(cur, delta))
  else ~1

fun parse_lines_resync_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, cur: int, len: int, stk: &Buf >> _,
  resync: !Buf, nres: int, delta: int, minpos: int, matched_old: &int >> _
): int =
  if recfuel > 0 then (
    if ige(cur, len) then cur
    else let
      val le = line_end(d, cur)
      val nxt = line_next(d, cur)
      var cols: int = 0
      var p: int = cur
      val () = indent_cols(d, cur, le, cols, p)
    in
      if ige(p, le) then parse_lines_resync_m(recfuel - 1, d, nxt, len, stk, resync, nres, delta, minpos, matched_old)
      else let
        val hit = check_resync_hit(resync, nres, cur, minpos, delta)
      in
        if ige(hit, 0) then (matched_old := hit; cur)
        else let
          val next_pos = dispatch_line(d, stk, cur, le, nxt, len, p)
        in
          parse_lines_resync_m(recfuel - 1, d, next_pos, len, stk, resync, nres, delta, minpos, matched_old)
        end
      end
    end
  ) else parse_lines_exh(d, cur, len, stk)

implement blk_parse_until(d, from, resync, nres, delta, minpos, stk, matched_old) = let
  val len = doc_len(d)
in
  parse_lines_resync_m(airlock_nat(MAX_REC_FUEL), d, from, len, stk, resync, nres, delta, minpos, matched_old)
end

implement ast_parse_all(d) = let
  val is_md = doc_is_md(d)
in
  if is_off(is_md) then (doc_clear_nodes(d); doc_set_span(d, 0))
  else let
    val () = doc_clear_nodes(d)
    var stk = buf_make(imul(64, 20))
    var res = buf_make(4)
    var matched_old: int = ~1
    val _ = blk_parse_until(d, 0, res, 0, 0, 0, stk, matched_old)
    val () = buf_free(res)
    val () = buf_free(stk)
    val () = doc_set_span(d, doc_len(d))
  in
  end
end

fun buf_push32(b: &Buf >> _, v: int): void = let
  val n = buf_len(b)
  val idx = idiv(n, 4)
  val need = iadd(n, 4)
  val () = if buf_cap(b) < need then buf_resize(b, imax(16, imul(need, 2))) else ()
  val () = buf_set_len(b, need)
  val () = buf_set32(b, idx, v)
in
end

fun save_node_flds1(d: !Doc, dst: &Buf >> _, cur: int): void = (
  buf_push32(dst, doc_get(d, cur, 0));
  buf_push32(dst, doc_get(d, cur, 1));
  buf_push32(dst, doc_get(d, cur, 2));
  buf_push32(dst, doc_get(d, cur, 3));
  buf_push32(dst, doc_get(d, cur, 4));
  buf_push32(dst, doc_get(d, cur, 5));
  buf_push32(dst, doc_get(d, cur, 6));
  buf_push32(dst, doc_get(d, cur, 7))
)

fun save_node_flds2(d: !Doc, dst: &Buf >> _, cur: int): void = (
  buf_push32(dst, doc_get(d, cur, 8));
  buf_push32(dst, doc_get(d, cur, 9));
  buf_push32(dst, doc_get(d, cur, 10));
  buf_push32(dst, doc_get(d, cur, 11));
  buf_push32(dst, doc_get(d, cur, 12));
  buf_push32(dst, doc_get(d, cur, 13));
  buf_push32(dst, doc_get(d, cur, 14));
  buf_push32(dst, doc_get(d, cur, 15))
)

fun save_old_nodes_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, dst: &Buf >> _, cur: int, total: int
): void =
  if recfuel > 0 then (
    if ige(cur, total) then ()
    else let
      val () = save_node_flds1(d, dst, cur)
      val () = save_node_flds2(d, dst, cur)
    in
      save_old_nodes_m(recfuel - 1, d, dst, iadd(cur, 1), total)
    end
  ) else ()

fun set_node_extra1(
  d: !Doc, old_b: !Buf, base: int, new_i: int, idxdelta: int
): void = let
  val dep = buf_get32(old_b, iadd(base, 3))
  val col = buf_get32(old_b, iadd(base, 4))
  val h = buf_get32(old_b, iadd(base, 5))
  val sib0 = buf_get32(old_b, iadd(base, 7))
  val sib = (if ige(sib0, 0) then iadd(sib0, idxdelta) else ~1)
  val fc0 = buf_get32(old_b, iadd(base, 8))
  val fc = (if ige(fc0, 0) then iadd(fc0, idxdelta) else ~1)
in
  doc_set(d, new_i, NF_DEPTH, dep);
  doc_set(d, new_i, NF_COLLAPSED, col);
  doc_set(d, new_i, NF_HEIGHT, h);
  doc_set(d, new_i, NF_NEXT_SIB, sib);
  doc_set(d, new_i, NF_FIRST_CHILD, fc)
end

fun set_node_extra2(
  d: !Doc, old_b: !Buf, base: int, new_i: int, delta: int, idxdelta: int
): void = let
  val hid = buf_get32(old_b, iadd(base, 9))
  val cs0 = buf_get32(old_b, iadd(base, 11))
  val cs = (if ige(cs0, 0) then iadd(cs0, delta) else cs0)
  val ce0 = buf_get32(old_b, iadd(base, 12))
  val ce = (if ige(ce0, 0) then iadd(ce0, delta) else ce0)
  val y = buf_get32(old_b, iadd(base, 13))
  val sub0 = buf_get32(old_b, iadd(base, 14))
  val sub = (if ige(sub0, 0) then iadd(sub0, idxdelta) else sub0)
in
  doc_set(d, new_i, NF_HIDDEN, hid);
  doc_set(d, new_i, NF_CSTART, cs);
  doc_set(d, new_i, NF_CEND, ce);
  doc_set(d, new_i, NF_Y, y);
  doc_set(d, new_i, NF_SUBEND, sub)
end

fun copy_one_node(
  d: !Doc, old_b: !Buf, idx: int, delta: int, idxdelta: int
): void = let
  val base = imul(idx, 16)
  val k_code = buf_get32(old_b, iadd(base, 0))
  val k = kind_of(k_code)
  val st = iadd(buf_get32(old_b, iadd(base, 1)), delta)
  val en = iadd(buf_get32(old_b, iadd(base, 2)), delta)
  val par0 = buf_get32(old_b, iadd(base, 6))
  val par = (if ige(par0, 0) then iadd(par0, idxdelta) else ~1)
  val aux = buf_get32(old_b, iadd(base, 10))
  val flg = buf_get32(old_b, iadd(base, 15))
  val new_i = doc_node_add(d, k, st, en, par, ~1, aux, flg)
in
  if ige(new_i, 0) then (
    set_node_extra1(d, old_b, base, new_i, idxdelta);
    set_node_extra2(d, old_b, base, new_i, delta, idxdelta)
  ) else ()
end

fun copy_tail_nodes_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, old_b: !Buf, cur: int, total: int, delta: int, idxdelta: int
): void =
  if recfuel > 0 then (
    if ige(cur, total) then ()
    else let
      val () = copy_one_node(d, old_b, cur, delta, idxdelta)
    in
      copy_tail_nodes_m(recfuel - 1, d, old_b, iadd(cur, 1), total, delta, idxdelta)
    end
  ) else ()

fun copy_head_nodes_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, old_b: !Buf, cur: int, n: int
): void =
  if recfuel > 0 then (
    if ige(cur, n) then ()
    else let
      val () = copy_one_node(d, old_b, cur, 0, 0)
    in
      copy_head_nodes_m(recfuel - 1, d, old_b, iadd(cur, 1), n)
    end
  ) else ()

extern fun find_last_top_exh(d: !Doc, cur: int, to_i: int, last: int): int = "mac#anth_die_int"

fun find_last_top_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, cur: int, to_i: int, last: int
): int =
  if recfuel > 0 then (
    if ige(cur, to_i) then last
    else let
      val sub = doc_node_subend(d, cur)
      val next_i = (if igt(sub, cur) then sub else iadd(cur, 1))
    in
      find_last_top_m(recfuel - 1, d, next_i, to_i, cur)
    end
  ) else find_last_top_exh(d, cur, to_i, last)

fun find_last_top(d: !Doc, from_i: int, to_i: int, default_val: int): int =
  find_last_top_m(airlock_nat(MAX_REC_FUEL), d, from_i, to_i, default_val)

extern fun find_top_exh(d: !Doc, off: int, cur: int, prev: int, p_top: &int >> _, c_top: &int >> _): void = "mac#anth_die_void"

fun find_top_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, off: int, cur: int, prev: int,
  p_top: &int >> _, c_top: &int >> _
): void =
  if recfuel > 0 then (
    if ige(cur, doc_nnodes(d)) then (p_top := prev; c_top := ~1)
    else let
      val st = doc_node_start(d, cur)
      val en = doc_node_end(d, cur)
      val sub = doc_node_subend(d, cur)
      val next_cur = (if igt(sub, cur) then sub else iadd(cur, 1))
    in
      if ige(off, st) andalso ile(off, en) then (p_top := prev; c_top := cur)
      else if ilt(off, st) then (p_top := prev; c_top := cur)
      else find_top_m(recfuel - 1, d, off, next_cur, cur, p_top, c_top)
    end
  ) else find_top_exh(d, off, cur, prev, p_top, c_top)

extern fun collect_res_exh(d: !Doc, resync: &Buf >> _, min_st: int, cur: int, count: int): int = "mac#anth_die_int"

fun collect_res_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, resync: &Buf >> _, min_st: int, cur: int, count: int
): int =
  if recfuel > 0 then (
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
        collect_res_m(recfuel - 1, d, resync, min_st, next_cur, iadd(count, 1))
      end else collect_res_m(recfuel - 1, d, resync, min_st, next_cur, count)
    end
  ) else collect_res_exh(d, resync, min_st, cur, count)

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
    val () = copy_tail_nodes_m(airlock_nat(MAX_REC_FUEL), d, old_b, matched_old, old_total, delta, idxdelta)
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
  var resync = buf_make(64)
  val nres = collect_res_m(airlock_nat(MAX_REC_FUEL), d, resync, iadd(at, oldlen), 0, 0)
  var old_b = buf_make(imul(old_total, 64))
  val () = save_old_nodes_m(airlock_nat(MAX_REC_FUEL), d, old_b, 0, old_total)
  val () = doc_clear_nodes(d)
  val () = copy_head_nodes_m(airlock_nat(MAX_REC_FUEL), d, old_b, 0, head_end)
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
      val () = find_top_m(airlock_nat(MAX_REC_FUEL), d, at, 0, ~1, p_top, c_top)
    in
      if ilt(c_top, 0) then ast_parse_all(d)
      else ast_reparse_do(d, at, oldlen, newlen, isub(newlen, oldlen), old_total, p_top, c_top)
    end
  end
end

