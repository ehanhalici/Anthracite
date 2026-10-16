fun stack_top_line(stk: !Buf): int = let
  val base = stack_top_base_word(stk)
in
  if base < 0 then ~1 else buf_get32(stk, iadd(base, STACK_FLD_LINE))
end

fun stack_top_ind(stk: !Buf): int = let
  val base = stack_top_base_word(stk)
in
  if base < 0 then ~1 else buf_get32(stk, iadd(base, STACK_FLD_IND))
end

fun stack_top_rank(stk: !Buf): int = let
  val base = stack_top_base_word(stk)
in
  if base < 0 then 0 else buf_get32(stk, iadd(base, STACK_FLD_RANK))
end

fun stack_top_last(stk: !Buf): int = let
  val base = stack_top_base_word(stk)
in
  if base < 0 then ~1 else buf_get32(stk, iadd(base, STACK_FLD_LAST))
end

fun stack_set_top_last(stk: !Buf, last: int): void = let
  val base = stack_top_base_word(stk)
in
  if base >= 0 then buf_set32(stk, iadd(base, STACK_FLD_LAST), last) else ()
end

fun stack_extend_last(stk: !Buf, line: int): void =
  stack_set_top_last(stk, imax(stack_top_last(stk), line))

fun stack_propagate_last(stk: !Buf, last: int): void =
  if stack_is_empty(stk) then () else stack_extend_last(stk, last)

fun stack_pop_one(
  stk: &Buf >> _, regions: &Buf >> _, close_line: int, d: !Doc
): void = let
  val len = buf_len(stk)
in
  if ige(len, SIZEOF_STACKFRAME) then let
    val line = stack_top_line(stk)
    val rank = stack_top_rank(stk)
    val last = stack_top_last(stk)
    val () = buf_set_len(stk, isub(len, SIZEOF_STACKFRAME))
    val () = stack_propagate_last(stk, last)
  in
    if igt(rank, 0) then (
      if igt(close_line, iadd(line, 1)) then
        fold_region_append(regions, line, close_line, doc_line_start(d, line), FR_HEADING)
      else ()
    ) else if igt(last, line) then
      fold_region_append(regions, line, iadd(last, 1), doc_line_start(d, line), FR_PLAIN)
    else ()
  end else ()
end

fun stack_unwind_heading_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), stk: &Buf >> _, regions: &Buf >> _, rank: int, cur_line: int, d: !Doc
): void =
  if recursion_fuel_available(recfuel) then (
    if stack_is_empty(stk) then ()
    else let
      val top_r = stack_top_rank(stk)
    in
      if igt(top_r, 0) andalso ilt(top_r, rank) then ()
      else let
        val () = stack_pop_one(stk, regions, cur_line, d)
      in
        stack_unwind_heading_with_fuel(recfuel - 1, stk, regions, rank, cur_line, d)
      end
    end
  ) else ()

fun stack_unwind_indent_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), stk: &Buf >> _, regions: &Buf >> _, ind: int, cur_line: int, d: !Doc
): void =
  if recursion_fuel_available(recfuel) then (
    if stack_is_empty(stk) then ()
    else let
      val top_r = stack_top_rank(stk)
      val top_i = stack_top_ind(stk)
    in
      if igt(top_r, 0) orelse ilt(top_i, ind) then stack_extend_last(stk, cur_line)
      else let
        val () = stack_pop_one(stk, regions, cur_line, d)
      in
        stack_unwind_indent_with_fuel(recfuel - 1, stk, regions, ind, cur_line, d)
      end
    end
  ) else ()

fun stack_drain_all_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), stk: &Buf >> _, regions: &Buf >> _, nlines: int, d: !Doc
): void =
  if recursion_fuel_available(recfuel) then (
    if stack_is_empty(stk) then ()
    else let
      val () = stack_pop_one(stk, regions, nlines, d)
    in
      stack_drain_all_with_fuel(recfuel - 1, stk, regions, nlines, d)
    end
  ) else ()

fun process_indented_line(
  d: !Doc, line: int, start: int, finish: int, stk: &Buf >> _, regions: &Buf >> _
): void =
  if line_is_empty_with_fuel(airlock_nat(MAX_REC_FUEL), d, start, finish) then ()
  else let
    val indent = line_visual_indent_with_fuel(airlock_nat(MAX_REC_FUEL), d, start, finish, 0)
    val () = stack_unwind_indent_with_fuel(airlock_nat(MAX_REC_FUEL), stk, regions, indent, line, d)
  in
    stack_push(stk, line, indent, 0, line)
  end

fun process_one_line(
  d: !Doc, line: int, stk: &Buf >> _, regions: &Buf >> _, delim_buf: !Buf, nlines: int
): void = let
  val is_delim = buf_get(delim_buf, line)
in
  if ieq(is_delim, 1) then ()
  else let
    val st = doc_line_start(d, line)
    val en = if ilt(iadd(line, 1), nlines) then doc_line_start(d, iadd(line, 1)) else doc_len(d)
    val rank = line_heading_rank(d, st, en)
  in
    if igt(rank, 0) then let
      val () = stack_unwind_heading_with_fuel(airlock_nat(MAX_REC_FUEL), stk, regions, rank, line, d)
      val () = stack_push(stk, line, 0, rank, line)
    in
    end else process_indented_line(d, line, st, en, stk, regions)
  end
end

extern fun scan_lines_m_fuel_exhausted(d: !Doc, line: int, nlines: int, stk: &Buf >> _, regions: &Buf >> _, delim_buf: !Buf): void = "mac#anth_die_void"

fun scan_lines_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, line: int, nlines: int, stk: &Buf >> _, regions: &Buf >> _, delim_buf: !Buf
): void =
  if recursion_fuel_available(recfuel) then (
    if line >= nlines then ()
    else let
      val () = process_one_line(d, line, stk, regions, delim_buf, nlines)
    in
      scan_lines_with_fuel(recfuel - 1, d, iadd(line, 1), nlines, stk, regions, delim_buf)
    end
  ) else scan_lines_m_fuel_exhausted(d, line, nlines, stk, regions, delim_buf)

fun region_fields(regions: !Buf, i: int): @(int, int, int, int) =
  @(fold_region_owner(regions, i), fold_region_end(regions, i),
    fold_region_offset(regions, i), fold_region_kind(regions, i))

fun regions_swap(regions: !Buf, i: int, j: int): void = let
  val @(o_i, e_i, f_i, k_i) = region_fields(regions, i)
  val @(o_j, e_j, f_j, k_j) = region_fields(regions, j)
  val bi = imul(i, FR_ENTRY_WORDS)
  val bj = imul(j, FR_ENTRY_WORDS)
  val () = buf_set32(regions, iadd(bi, FR_OWNER), o_j)
  val () = buf_set32(regions, iadd(bi, FR_END), e_j)
  val () = buf_set32(regions, iadd(bi, FR_OFFSET), f_j)
  val () = buf_set32(regions, iadd(bi, FR_KIND), k_j)
  val () = buf_set32(regions, iadd(bj, FR_OWNER), o_i)
  val () = buf_set32(regions, iadd(bj, FR_END), e_i)
  val () = buf_set32(regions, iadd(bj, FR_OFFSET), f_i)
  val () = buf_set32(regions, iadd(bj, FR_KIND), k_i)
in
end

fun regions_sort_inner_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), regions: !Buf, j: int
): void =
  if recursion_fuel_available(recfuel) then (
    if j <= 0 then ()
    else let
      val prev = isub(j, 1)
      val o_cur = fold_region_owner(regions, j)
      val o_prev = fold_region_owner(regions, prev)
    in
      if ilt(o_cur, o_prev) then let
        val () = regions_swap(regions, prev, j)
      in
        regions_sort_inner_with_fuel(recfuel - 1, regions, prev)
      end else ()
    end
  ) else ()

fun regions_sort_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), regions: !Buf, i: int, n: int
): void =
  if recursion_fuel_available(recfuel) then (
    if i >= n then ()
    else let
      val () = regions_sort_inner_with_fuel(airlock_nat(MAX_REC_FUEL), regions, i)
    in
      regions_sort_with_fuel(recfuel - 1, regions, iadd(i, 1), n)
    end
  ) else ()
