extern fun line_end_fuel_exhausted(d: !Doc, p: int, len: int): int = "mac#anth_die_int"

fun line_end_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, len: int
): int =
  if recfuel > 0 then (
    if ige(p, len) then p
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, CHAR_LF) then (
        if igt(p, 0) andalso ieq(doc_byte(d, isub(p, 1)), CHAR_CR) then isub(p, 1) else p
      ) else line_end_with_fuel(recfuel - 1, d, iadd(p, 1), len)
    end
  ) else line_end_fuel_exhausted(d, p, len)

implement line_end(d, ls) =
  line_end_with_fuel(airlock_nat(MAX_REC_FUEL), d, ls, doc_len(d))

extern fun line_next_fuel_exhausted(d: !Doc, p: int, len: int): int = "mac#anth_die_int"

fun line_next_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, len: int
): int =
  if recfuel > 0 then (
    if ige(p, len) then p
    else if ieq(doc_byte(d, p), CHAR_LF) then iadd(p, 1)
    else line_next_with_fuel(recfuel - 1, d, iadd(p, 1), len)
  ) else line_next_fuel_exhausted(d, p, len)

implement line_next(d, ls) =
  line_next_with_fuel(airlock_nat(MAX_REC_FUEL), d, ls, doc_len(d))

extern fun indent_cols_fuel_exhausted(d: !Doc, p: int, le: int, c: int): void = "mac#anth_die_void"

fun indent_cols_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, le: int, c: int,
  cols: &int >> _, next_p: &int >> _
): void =
  if recfuel > 0 then (
    if ige(p, le) then (cols := c; next_p := p)
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, CHAR_SPACE) then indent_cols_with_fuel(recfuel - 1, d, iadd(p, 1), le, iadd(c, 1), cols, next_p)
      else if ieq(b, CHAR_TAB) then let
        val next_c = imul(iadd(idiv(c, 4), 1), 4)
      in
        indent_cols_with_fuel(recfuel - 1, d, iadd(p, 1), le, next_c, cols, next_p)
      end else (cols := c; next_p := p)
    end
  ) else indent_cols_fuel_exhausted(d, p, le, c)

implement indent_cols(d, p, le, cols, next_p) =
  indent_cols_with_fuel(airlock_nat(MAX_REC_FUEL), d, p, le, 0, cols, next_p)

extern fun is_blank_fuel_exhausted(d: !Doc, p: int, le: int): bool = "mac#anth_die_int"

fun is_blank_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, le: int
): bool =
  if recfuel > 0 then (
    if ige(p, le) then true
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, CHAR_SPACE) orelse ieq(b, CHAR_TAB) then is_blank_with_fuel(recfuel - 1, d, iadd(p, 1), le)
      else false
    end
  ) else is_blank_fuel_exhausted(d, p, le)

implement is_blank(d, p, le) =
  is_blank_with_fuel(airlock_nat(MAX_REC_FUEL), d, p, le)

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

extern fun count_char_fuel_exhausted(d: !Doc, p: int, le: int, ch: int, c: int): int = "mac#anth_die_int"

fun count_char_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, le: int, ch: int, c: int
): int =
  if recfuel > 0 then (
    if ige(p, le) then c
    else if ieq(doc_byte(d, p), ch) then count_char_with_fuel(recfuel - 1, d, iadd(p, 1), le, ch, iadd(c, 1))
    else c
  ) else count_char_fuel_exhausted(d, p, le, ch, c)

fun count_char(d: !Doc, p: int, le: int, ch: int): int =
  count_char_with_fuel(airlock_nat(MAX_REC_FUEL), d, p, le, ch, 0)

fun is_space_or_tab(b: int): bool = ieq(b, CHAR_SPACE) orelse ieq(b, CHAR_TAB)

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

extern fun find_close_fence_fuel_exhausted(d: !Doc, cur: int, len: int, ch: int, flen: int, c_st: &int >> _, c_en: &int >> _): bool = "mac#anth_die_int"

fun find_close_fence_with_fuel {recfuel:nat} .<recfuel>. (
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
      ) else find_close_fence_with_fuel(recfuel - 1, d, nxt, len, ch, flen, c_st, c_en)
    end
  ) else find_close_fence_fuel_exhausted(d, cur, len, ch, flen, c_st, c_en)

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
