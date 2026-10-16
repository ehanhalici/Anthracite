extern fun gather_fuel_exhausted(d: !Doc, i: int, re: int, pred: Gather): int = "mac#anth_die_int"

fun gather_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int, pred: Gather): int =
  if recursion_fuel_available(recfuel) then (
    if ige(i, re) then i
    else if blank_line(d, i, re) then i
    else if is_gather(pred, GatherQuote) andalso not(is_quote(d, i, re)) then i
    else if is_gather(pred, GatherTable) andalso not(is_table(d, i, re)) then i
    else if is_gather(pred, GatherAny) andalso (is_fence(d, i, re) orelse is_heading(d, i, re) orelse is_hr(d, i, re) orelse is_ul(d, i, re) orelse is_ol(d, i, re) orelse is_task(d, i, re) orelse is_quote(d, i, re) orelse is_table(d, i, re) orelse is_fndef(d, i, re)) then i
    else let
      val e = at_end(d, i, re)
      val n = if ilt(e, re) andalso ieq(doc_byte(d, e), CHAR_LF) then iadd(e, 1) else e
    in
      gather_with_fuel(recfuel - 1, d, n, re, pred)
    end
  ) else gather_fuel_exhausted(d, i, re, pred)

fun gather(d: !Doc, i: int, re: int, pred: Gather): int = gather_with_fuel(airlock_nat(MAX_REC_FUEL), d, i, re, pred)

extern fun fm_close_fuel_exhausted(d: !Doc, re: int, k: int): int = "mac#anth_die_int"

fun fm_close_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, re: int, k: int): int =
  if recursion_fuel_available(recfuel) then (
    if ige(k, re) then re
    else if starts_at(d, skip_sp(d, k, re), re, "---") then let
      val e = at_end(d, k, re)
    in
      if ilt(e, re) then iadd(e, 1) else e
    end else fm_close_with_fuel(recfuel - 1, d, re, if ilt(at_end(d, k, re), re) then iadd(at_end(d, k, re), 1) else re)
  ) else fm_close_fuel_exhausted(d, re, k)

fun fm_close(d: !Doc, re: int, k: int): int = fm_close_with_fuel(airlock_nat(MAX_REC_FUEL), d, re, k)

extern fun fence_close_fuel_exhausted(d: !Doc, re: int, k: int): int = "mac#anth_die_int"

fun fence_close_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, re: int, k: int): int =
  if recursion_fuel_available(recfuel) then (
    if ige(k, re) then re
    else if is_fence(d, k, re) then let
      val e = at_end(d, k, re)
    in
      if ilt(e, re) then iadd(e, 1) else e
    end else let
      val e = at_end(d, k, re)
    in
      fence_close_with_fuel(recfuel - 1, d, re, if ilt(e, re) then iadd(e, 1) else re)
    end
  ) else fence_close_fuel_exhausted(d, re, k)

fun fence_close(d: !Doc, re: int, k: int): int = fence_close_with_fuel(airlock_nat(MAX_REC_FUEL), d, re, k)

fun parse_frontmatter(d: !Doc, i: int, re: int, depth: int): int = let
  val e1 = at_end(d, i, re)
  val n1 = if ilt(e1, re) then iadd(e1, 1) else e1
  val en = fm_close(d, re, n1)
  val () = node_append(d, KFm, i, en, depth, 0)
in
  en
end

fun parse_fence(d: !Doc, i: int, re: int, depth: int): int = let
  val e1 = at_end(d, i, re)
  val n1 = if ilt(e1, re) then iadd(e1, 1) else e1
  val en = fence_close(d, re, n1)
  val () = node_append(d, KCode, i, en, depth, 0)
in
  en
end

fun parse_hr(d: !Doc, i: int, re: int, depth: int): int = let
  val e = at_end(d, i, re)
  val n = if ilt(e, re) then iadd(e, 1) else e
  val () = node_append(d, KHr, i, n, depth, 0)
in
  n
end

fun parse_heading(d: !Doc, i: int, re: int, depth: int, hashes: int): int = let
  val e = at_end(d, i, re)
  val n = if ilt(e, re) then iadd(e, 1) else e
  val kind = heading_kind(hashes)
  val () = node_append(d, kind, i, n, depth, hashes)
  val () = emit_inlines(d, i, e, iadd(depth, 1))
in
  n
end

fun parse_fndef(d: !Doc, i: int, re: int, depth: int): int = let
  val e = at_end(d, i, re)
  val n = if ilt(e, re) then iadd(e, 1) else e
  val () = node_append(d, KFndef, i, n, depth, 0)
in
  n
end

fun parse_task(d: !Doc, i: int, re: int, depth: int, sp: int): int = let
  val e = at_end(d, i, re)
  val n = if ilt(e, re) then iadd(e, 1) else e
  val () = node_append(d, KTask, i, n, iadd(depth, idiv(isub(sp, i), 2)), task_aux(d, i, re))
  val () = emit_inlines(d, i, e, iadd(depth, 1))
in
  n
end

fun parse_ul(d: !Doc, i: int, re: int, depth: int, sp: int): int = let
  val e = at_end(d, i, re)
  val n = if ilt(e, re) then iadd(e, 1) else e
  val () = node_append(d, KLi, i, n, iadd(depth, idiv(isub(sp, i), 2)), 0)
  val () = node_append(d, KUl, i, n, depth, 0)
  val () = emit_inlines(d, i, e, iadd(depth, 1))
in
  n
end

fun parse_ol(d: !Doc, i: int, re: int, depth: int, sp: int): int = let
  val e = at_end(d, i, re)
  val n = if ilt(e, re) then iadd(e, 1) else e
  val () = node_append(d, KLi, i, n, iadd(depth, idiv(isub(sp, i), 2)), 1)
  val () = node_append(d, KOl, i, n, depth, 0)
  val () = emit_inlines(d, i, e, iadd(depth, 1))
in
  n
end

fun parse_quote(d: !Doc, i: int, re: int, depth: int): int = let
  val en = gather(d, i, re, GatherQuote)
  val () = node_append(d, KQuote, i, en, depth, 0)
  val () = emit_inlines(d, i, en, iadd(depth, 1))
in
  forward(d, i, re, en)
end

fun parse_table(d: !Doc, i: int, re: int, depth: int): int = let
  val en = gather(d, i, re, GatherTable)
  val () = node_append(d, KTable, i, en, depth, 0)
  val () = node_append(d, KTd, i, en, iadd(depth, 1), 0)
in
  forward(d, i, re, en)
end

fun parse_para(d: !Doc, i: int, re: int, depth: int): int = let
  val en = gather(d, i, re, GatherAny)
  val () = node_append(d, KPara, i, en, depth, 0)
  val () = emit_inlines(d, i, en, iadd(depth, 1))
in
  forward(d, i, re, en)
end

fun parse_line_block(d: !Doc, i: int, re: int, depth: int): int = let
  val sp = skip_sp(d, i, re)
  val hashes = count_hash(d, sp, re, 0)
in
  if is_heading(d, i, re) then parse_heading(d, i, re, depth, hashes)
  else if is_fndef(d, i, re) then parse_fndef(d, i, re, depth)
  else if is_task(d, i, re) then parse_task(d, i, re, depth, sp)
  else if is_ul(d, i, re) then parse_ul(d, i, re, depth, sp)
  else if is_ol(d, i, re) then parse_ol(d, i, re, depth, sp)
  else if is_quote(d, i, re) then parse_quote(d, i, re, depth)
  else if is_table(d, i, re) then parse_table(d, i, re, depth)
  else parse_para(d, i, re, depth)
end

extern fun parse_blocks_fuel_exhausted(d: !Doc, i: int, re: int, depth: int): void = "mac#anth_die_void"

fun parse_blocks_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int, depth: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(i, re) then ()
    else if blank_line(d, i, re) then let
      val e = at_end(d, i, re)
    in
      parse_blocks_with_fuel(recfuel - 1, d, if ilt(e, re) then iadd(e, 1) else e, re, depth)
    end
    else if ieq(i, 0) andalso starts_at(d, skip_sp(d, i, re), re, "---") then parse_blocks_with_fuel(recfuel - 1, d, parse_frontmatter(d, i, re, depth), re, depth)
    else if is_fence(d, i, re) then parse_blocks_with_fuel(recfuel - 1, d, parse_fence(d, i, re, depth), re, depth)
    else if is_hr(d, i, re) then parse_blocks_with_fuel(recfuel - 1, d, parse_hr(d, i, re, depth), re, depth)
    else parse_blocks_with_fuel(recfuel - 1, d, parse_line_block(d, i, re, depth), re, depth)
  ) else parse_blocks_fuel_exhausted(d, i, re, depth)

fun parse_blocks(d: !Doc, i: int, re: int, depth: int): void = parse_blocks_with_fuel(airlock_nat(MAX_REC_FUEL), d, i, re, depth)

implement doc_parse_range(d, rs, re) =
  parse_blocks(d, rs, re, 0)
