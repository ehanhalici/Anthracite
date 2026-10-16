fun node_append(d: !Doc, kind: NodeKind, st: int, en: int, depth: int, aux: int): void = let
  val () = node_room(d)
  val i = d_nnodes(d)
  val () = zero_node_with_fuel(airlock_nat(MAX_REC_FUEL), d, i, 0)
  val () = node_field_set(d, i, NF_KIND, kind_code(kind))
  val () = node_field_set(d, i, NF_START, st)
  val () = node_field_set(d, i, NF_END, en)
  val () = node_field_set(d, i, NF_DEPTH, depth)
  val () = doc_node_set_parent(d, i, ~1)
  val () = doc_node_set_next_sib(d, i, ~1)
  val () = doc_node_set_first_child(d, i, ~1)
  val () = node_field_set(d, i, NF_AUX, aux)
  val () = d_set_nnodes(d, iadd(i, 1))
in
end

implement doc_push_node(d, kind, st, en, depth, aux) =
  node_append(d, kind, st, en, depth, aux)

implement doc_node_add(d, kind, st, en, parent, prev_sib, aux, flags) = let
  val n = d_nnodes(d)
  val len = d_len(d)
in
  if st < 0 orelse st >= en orelse en > len orelse n >= MAX_NODES then ~1
  else let
    val dp = (if parent >= 0 then iadd(doc_node_depth(d, parent), 1) else 0)
    val () = node_append(d, kind, st, en, dp, aux)
    val () = node_field_set(d, n, NF_CSTART, st)
    val () = node_field_set(d, n, NF_CEND, en)
    val () = node_field_set(d, n, NF_PARENT, parent)
    val () = node_field_set(d, n, NF_SUBEND, iadd(n, 1))
    val () = node_field_set(d, n, NF_FLAGS, flags)
    val () =
      if prev_sib >= 0 then node_field_set(d, prev_sib, NF_NEXT_SIB, n)
      else if parent >= 0 then node_field_set(d, parent, NF_FIRST_CHILD, n)
      else ()
  in
    n
  end
end

implement doc_node_close(d, i, en, cs, ce) = let
  val n = d_nnodes(d)
in
  if i < 0 orelse i >= n then ()
  else let
    val () = node_field_set(d, i, NF_END, en)
    val () = node_field_set(d, i, NF_CSTART, cs)
    val () = node_field_set(d, i, NF_CEND, ce)
    val () = node_field_set(d, i, NF_SUBEND, n)
  in
  end
end

extern fun doc_find_child_fuel_exhausted(d: !Doc, c: int, kind: NodeKind): int = "mac#anth_die_int"

fun doc_find_child_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, c: int, kind: NodeKind
): int =
  if recursion_fuel_available(recfuel) then (
    if c < 0 orelse c >= d_nnodes(d) then ~1
    else if is_kind(doc_node_kind(d, c), kind) then c
    else doc_find_child_with_fuel(recfuel - 1, d, doc_node_next_sib(d, c), kind)
  ) else doc_find_child_fuel_exhausted(d, c, kind)

implement doc_find_child(d, i, kind) = let
  val n = d_nnodes(d)
in
  if i < 0 orelse i >= n then ~1
  else let
    val fc = doc_node_first_child(d, i)
  in
    doc_find_child_with_fuel(airlock_nat(MAX_REC_FUEL), d, fc, kind)
  end
end

implement doc_ver(d) = d_ver(d)

implement doc_layout_version(d) = d_ver(d)

implement doc_layout_cache_match(d, version, key, mode) =
  case+ d of
  | @DOC(s) => let
      val hit = layout_cache_matches(s.lay, version, key, mode)
    in
      fold@(d); hit
    end

implement doc_layout_cache_height(d) =
  case+ d of
  | @DOC(s) => let
      val height = layout_cache_height(s.lay)
    in
      fold@(d); height
    end

implement doc_layout_cache_store(d, version, key, height, mode, wrap) =
  case+ d of
  | @DOC(s) => let
      val () = layout_cache_store(s.lay, version, key, height, mode, wrap)
    in
      fold@(d)
    end

implement doc_layout_cached_wrap(d) =
  case+ d of
  | @DOC(s) => let
      val wrap = layout_wrap(s.lay)
    in
      fold@(d); wrap
    end

implement doc_clear_nodes(d) =
  case+ d of
  | @DOC(s) => let
      val b = s.nodes
      val () = buf_set_len(b, 0)
      val () = s.nodes := b
      val () = s.nnodes := 0
    in
      fold@(d)
    end

fun is_delimited_block(k: NodeKind): bool =
  is_kind(k, KCode) orelse is_kind(k, KQuote) orelse is_kind(k, KCallout) orelse is_kind(k, KFm)

implement doc_node_fold_body_start(d, i) = let
  val n = d_nnodes(d)
in
  if i < 0 orelse i >= n then 0
  else let
    val st = doc_node_start(d, i)
    val line = doc_line_of(d, st)
    val next_line = iadd(line, 1)
  in
    if ilt(next_line, doc_nlines(d)) then doc_line_start(d, next_line)
    else doc_len(d)
  end
end

implement doc_node_fold_end(d, i) = let
  val n = d_nnodes(d)
in
  if i < 0 orelse i >= n then 0
  else let
    val st = doc_node_start(d, i)
    val line = doc_line_of(d, st)
    val reg = doc_line_region(d, line)
  in
    if reg < 0 then 0
    else let
      val fend_l = doc_region_end(d, reg)
    in
      if ilt(fend_l, doc_nlines(d)) then doc_line_start(d, fend_l)
      else doc_len(d)
    end
  end
end

extern fun count_nl_fuel_exhausted(d: !Doc, p: int, en: int, lines: int): int = "mac#anth_die_int"

fun count_nl_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, p: int, en: int, lines: int): int =
  if recursion_fuel_available(recfuel) then (
    if ige(p, en) then lines
    else count_nl_with_fuel(recfuel - 1, d, iadd(p, 1), en, (if ieq(doc_byte(d, p), CHAR_LF) then iadd(lines, 1) else lines))
  ) else count_nl_fuel_exhausted(d, p, en, lines)

fun count_nl(d: !Doc, p: int, en: int, lines: int): int = count_nl_with_fuel(airlock_nat(MAX_REC_FUEL), d, p, en, lines)

implement doc_is_foldable(d, i) = let
  val n = d_nnodes(d)
in
  if i < 0 orelse i >= n then false
  else iand(doc_node_flags(d, i), FL_FOLDABLE) != 0
end

extern fun clear_flags_m_fuel_exhausted(d: !Doc, i: int, n: int): void = "mac#anth_die_void"

fun clear_flags_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, i: int, n: int
): void =
  if recursion_fuel_available(recfuel) then (
    if i >= n then ()
    else let
      val fl = doc_node_flags(d, i)
      val new_fl = (if ine(iand(fl, FL_FOLDABLE), 0) then isub(fl, FL_FOLDABLE) else fl)
      val () = node_field_set(d, i, NF_FLAGS, new_fl)
      val () = node_field_set(d, i, NF_COLLAPSED, 0)
    in
      clear_flags_with_fuel(recfuel - 1, d, iadd(i, 1), n)
    end
  ) else clear_flags_m_fuel_exhausted(d, i, n)

fun node_block_rank(k: NodeKind): int =
  if is_heading(k) then 4
  else if is_delimited_block(k) then 3
  else if is_kind(k, KLi) then 2
  else if is_kind(k, KPara) then 1
  else 0
