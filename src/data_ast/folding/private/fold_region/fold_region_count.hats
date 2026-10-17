implement fold_region_count(regions) =
  idiv(buf_len(regions), FR_ENTRY_BYTES)

implement fold_region_owner(regions, idx) =
  buf_get32(regions, iadd(imul(idx, FR_ENTRY_WORDS), FR_OWNER))

implement fold_region_end(regions, idx) =
  buf_get32(regions, iadd(imul(idx, FR_ENTRY_WORDS), FR_END))

implement fold_region_offset(regions, idx) =
  buf_get32(regions, iadd(imul(idx, FR_ENTRY_WORDS), FR_OFFSET))

implement fold_region_kind(regions, idx) =
  buf_get32(regions, iadd(imul(idx, FR_ENTRY_WORDS), FR_KIND))

fun fold_region_append(
  regions: &Buf >> _, owner: int, fend: int, off: int, kind: int
): void =
  if igt(fend, iadd(owner, 1)) then let
    val n = fold_region_count(regions)
    val base = imul(n, FR_ENTRY_WORDS)
    val nbytes = imul(iadd(base, FR_ENTRY_WORDS), BYTES_PER_WORD)
    val () = buf_ensure(regions, nbytes)
    val () = buf_set32(regions, iadd(base, FR_OWNER), owner)
    val () = buf_set32(regions, iadd(base, FR_END), fend)
    val () = buf_set32(regions, iadd(base, FR_OFFSET), off)
    val () = buf_set32(regions, iadd(base, FR_KIND), kind)
    val () = buf_set_len(regions, nbytes)
  in
  end else ()

extern fun fold_region_of_line_fuel_exhausted(regions: !Buf, line: int, i: int, n: int): int = "mac#anth_die_int"

fun fold_region_of_line_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), regions: !Buf, line: int, i: int, n: int
): int =
  if recursion_fuel_available(recfuel) then (
    if i >= n then ~1
    else if ieq(fold_region_owner(regions, i), line) then i
    else fold_region_of_line_with_fuel(recfuel - 1, regions, line, iadd(i, 1), n)
  ) else fold_region_of_line_fuel_exhausted(regions, line, i, n)

implement fold_region_of_line(regions, line) =
  fold_region_of_line_with_fuel(airlock_nat(MAX_REC_FUEL), regions, line, 0, fold_region_count(regions))

extern fun fold_region_find_by_offset_fuel_exhausted(regions: !Buf, off: int, i: int, n: int): int = "mac#anth_die_int"

fun fold_region_find_by_offset_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), regions: !Buf, off: int, i: int, n: int
): int =
  if recursion_fuel_available(recfuel) then (
    if i >= n then ~1
    else if ieq(fold_region_offset(regions, i), off) then i
    else fold_region_find_by_offset_with_fuel(recfuel - 1, regions, off, iadd(i, 1), n)
  ) else fold_region_find_by_offset_fuel_exhausted(regions, off, i, n)

implement fold_region_find_by_offset(regions, off) =
  fold_region_find_by_offset_with_fuel(airlock_nat(MAX_REC_FUEL), regions, off, 0, fold_region_count(regions))

fun line_skip_ws_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int
): int =
  if recursion_fuel_available(recfuel) then (
    if p >= en then en
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, CHAR_SPACE) orelse ieq(b, CHAR_TAB) then line_skip_ws_with_fuel(recfuel - 1, d, iadd(p, 1), en)
      else p
    end
  ) else en

fun line_visual_indent_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, col: int
): int =
  if recursion_fuel_available(recfuel) then (
    if p >= en then col
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, CHAR_SPACE) then line_visual_indent_with_fuel(recfuel - 1, d, iadd(p, 1), en, iadd(col, 1))
      else if ieq(b, CHAR_TAB) then line_visual_indent_with_fuel(recfuel - 1, d, iadd(p, 1), en, iadd(col, TAB_WIDTH_SPACES))
      else col
    end
  ) else col

fun line_is_empty_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int
): bool =
  if recursion_fuel_available(recfuel) then (
    if p >= en then true
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, CHAR_SPACE) orelse ieq(b, CHAR_TAB) orelse ieq(b, CHAR_LF) orelse ieq(b, CHAR_CR) then
        line_is_empty_with_fuel(recfuel - 1, d, iadd(p, 1), en)
      else false
    end
  ) else true

fun line_heading_rank_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, hashes: int
): int =
  if recursion_fuel_available(recfuel) then (
    if p >= en then (if igt(hashes, 0) andalso ile(hashes, MAX_HEADING_LEVEL) then hashes else 0)
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, CHAR_HASH) then line_heading_rank_with_fuel(recfuel - 1, d, iadd(p, 1), en, iadd(hashes, 1))
      else if igt(hashes, 0) andalso ile(hashes, MAX_HEADING_LEVEL) andalso (ieq(b, CHAR_SPACE) orelse ieq(b, CHAR_TAB) orelse ieq(b, CHAR_LF) orelse ieq(b, CHAR_CR)) then
        hashes
      else 0
    end
  ) else 0

fun line_heading_rank(d: !Doc, st: int, en: int): int = let
  val p = line_skip_ws_with_fuel(airlock_nat(MAX_REC_FUEL), d, st, en)
in
  line_heading_rank_with_fuel(airlock_nat(MAX_REC_FUEL), d, p, en, 0)
end

fun mark_delim_range_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), delim_buf: !Buf, line: int, finish: int
): void =
  if recursion_fuel_available(recfuel) then (
    if line >= finish then ()
    else let
      val () = buf_set(delim_buf, line, 1)
    in
      mark_delim_range_with_fuel(recfuel - 1, delim_buf, iadd(line, 1), finish)
    end
  ) else ()

fun check_node_delimited(k: NodeKind): bool =
  is_kind(k, KCode) orelse is_kind(k, KQuote) orelse is_kind(k, KCallout) orelse is_kind(k, KFm)

fun collect_one_delimited(
  d: !Doc, i: int, regions: &Buf >> _, delim_buf: !Buf
): void = let
  val k = doc_node_kind(d, i)
in
  if check_node_delimited(k) then let
    val st = doc_node_start(d, i)
    val en = doc_node_end(d, i)
    val l_st = doc_line_of(d, st)
    val l_en = doc_line_of(d, imax(st, isub(en, 1)))
  in
    if igt(l_en, l_st) then let
      val fend = iadd(l_en, 1)
      val () = fold_region_append(regions, l_st, fend, doc_line_start(d, l_st), FR_DELIMITED)
      val () = mark_delim_range_with_fuel(airlock_nat(MAX_REC_FUEL), delim_buf, iadd(l_st, 1), fend)
    in
    end else ()
  end else ()
end

extern fun collect_delimited_m_fuel_exhausted(d: !Doc, i: int, n: int, regions: &Buf >> _, delim_buf: !Buf): void = "mac#anth_die_void"

fun collect_delimited_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, i: int, n: int, regions: &Buf >> _, delim_buf: !Buf
): void =
  if recursion_fuel_available(recfuel) then (
    if i >= n then ()
    else let
      val () = collect_one_delimited(d, i, regions, delim_buf)
    in
      collect_delimited_with_fuel(recfuel - 1, d, iadd(i, 1), n, regions, delim_buf)
    end
  ) else collect_delimited_m_fuel_exhausted(d, i, n, regions, delim_buf)

(* StackFrame structure layout (4 32-bit words = 16 bytes):
 * [0]: line (owner line)
 * [1]: ind  (indentation level in spaces)
 * [2]: rank (heading rank 1..6, or 0 for indent)
 * [3]: last (furthest line in scope)
 *)
macdef STACK_FLD_LINE = 0
macdef STACK_FLD_IND  = 1
macdef STACK_FLD_RANK = 2
macdef STACK_FLD_LAST = 3
macdef STACK_FRAME_WORDS = 4
macdef SIZEOF_STACKFRAME = STACK_FRAME_WORDS * BYTES_PER_WORD

fun stack_frame_count(stk: !Buf): int =
  idiv(buf_len(stk), SIZEOF_STACKFRAME)

fun stack_is_empty(stk: !Buf): bool =
  ilt(buf_len(stk), SIZEOF_STACKFRAME)

fun stack_top_base_word(stk: !Buf): int = let
  val len = buf_len(stk)
in
  if ilt(len, SIZEOF_STACKFRAME) then ~1
  else isub(idiv(len, BYTES_PER_WORD), STACK_FRAME_WORDS)
end

fun stack_push(
  stk: &Buf >> _, line: int, ind: int, rank: int, last: int
): void = let
  val frames = stack_frame_count(stk)
  val base = imul(frames, STACK_FRAME_WORDS)
  val nbytes = imul(iadd(base, STACK_FRAME_WORDS), BYTES_PER_WORD)
  val () = buf_ensure(stk, nbytes)
  val () = buf_set32(stk, iadd(base, STACK_FLD_LINE), line)
  val () = buf_set32(stk, iadd(base, STACK_FLD_IND), ind)
  val () = buf_set32(stk, iadd(base, STACK_FLD_RANK), rank)
  val () = buf_set32(stk, iadd(base, STACK_FLD_LAST), last)
  val () = buf_set_len(stk, nbytes)
in
end
