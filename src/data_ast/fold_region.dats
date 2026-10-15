#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "airlock.sats"
staload "mem.sats"
staload "data_ast/doc.sats"
staload "data_ast/fold_region.sats"

(* Markdown & parsing constants *)
macdef CHAR_CR = 13
macdef TAB_WIDTH_SPACES = 4
macdef MAX_HEADING_LEVEL = 6
macdef INITIAL_BUF_BYTES = 16
macdef INITIAL_STACK_BYTES = 256

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

extern fun fold_region_of_line_exh(regions: !Buf, line: int, i: int, n: int): int = "mac#anth_die_int"

fun fold_region_of_line_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), regions: !Buf, line: int, i: int, n: int
): int =
  if recfuel > 0 then (
    if i >= n then ~1
    else if ieq(fold_region_owner(regions, i), line) then i
    else fold_region_of_line_m(recfuel - 1, regions, line, iadd(i, 1), n)
  ) else fold_region_of_line_exh(regions, line, i, n)

implement fold_region_of_line(regions, line) =
  fold_region_of_line_m(airlock_nat(MAX_REC_FUEL), regions, line, 0, fold_region_count(regions))

extern fun fold_region_find_by_offset_exh(regions: !Buf, off: int, i: int, n: int): int = "mac#anth_die_int"

fun fold_region_find_by_offset_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), regions: !Buf, off: int, i: int, n: int
): int =
  if recfuel > 0 then (
    if i >= n then ~1
    else if ieq(fold_region_offset(regions, i), off) then i
    else fold_region_find_by_offset_m(recfuel - 1, regions, off, iadd(i, 1), n)
  ) else fold_region_find_by_offset_exh(regions, off, i, n)

implement fold_region_find_by_offset(regions, off) =
  fold_region_find_by_offset_m(airlock_nat(MAX_REC_FUEL), regions, off, 0, fold_region_count(regions))

fun line_skip_ws_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int
): int =
  if recfuel > 0 then (
    if p >= en then en
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, CHAR_SPACE) orelse ieq(b, CHAR_TAB) then line_skip_ws_m(recfuel - 1, d, iadd(p, 1), en)
      else p
    end
  ) else en

fun line_visual_indent_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, col: int
): int =
  if recfuel > 0 then (
    if p >= en then col
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, CHAR_SPACE) then line_visual_indent_m(recfuel - 1, d, iadd(p, 1), en, iadd(col, 1))
      else if ieq(b, CHAR_TAB) then line_visual_indent_m(recfuel - 1, d, iadd(p, 1), en, iadd(col, TAB_WIDTH_SPACES))
      else col
    end
  ) else col

fun line_is_empty_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int
): bool =
  if recfuel > 0 then (
    if p >= en then true
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, CHAR_SPACE) orelse ieq(b, CHAR_TAB) orelse ieq(b, CHAR_LF) orelse ieq(b, CHAR_CR) then
        line_is_empty_m(recfuel - 1, d, iadd(p, 1), en)
      else false
    end
  ) else true

fun line_heading_rank_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, hashes: int
): int =
  if recfuel > 0 then (
    if p >= en then (if igt(hashes, 0) andalso ile(hashes, MAX_HEADING_LEVEL) then hashes else 0)
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, CHAR_HASH) then line_heading_rank_m(recfuel - 1, d, iadd(p, 1), en, iadd(hashes, 1))
      else if igt(hashes, 0) andalso ile(hashes, MAX_HEADING_LEVEL) andalso (ieq(b, CHAR_SPACE) orelse ieq(b, CHAR_TAB) orelse ieq(b, CHAR_LF) orelse ieq(b, CHAR_CR)) then
        hashes
      else 0
    end
  ) else 0

fun line_heading_rank(d: !Doc, st: int, en: int): int = let
  val p = line_skip_ws_m(airlock_nat(MAX_REC_FUEL), d, st, en)
in
  line_heading_rank_m(airlock_nat(MAX_REC_FUEL), d, p, en, 0)
end

fun mark_delim_range_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), delim_buf: !Buf, line: int, finish: int
): void =
  if recfuel > 0 then (
    if line >= finish then ()
    else let
      val () = buf_set(delim_buf, line, 1)
    in
      mark_delim_range_m(recfuel - 1, delim_buf, iadd(line, 1), finish)
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
      val () = mark_delim_range_m(airlock_nat(MAX_REC_FUEL), delim_buf, iadd(l_st, 1), fend)
    in
    end else ()
  end else ()
end

extern fun collect_delimited_m_exh(d: !Doc, i: int, n: int, regions: &Buf >> _, delim_buf: !Buf): void = "mac#anth_die_void"

fun collect_delimited_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, i: int, n: int, regions: &Buf >> _, delim_buf: !Buf
): void =
  if recfuel > 0 then (
    if i >= n then ()
    else let
      val () = collect_one_delimited(d, i, regions, delim_buf)
    in
      collect_delimited_m(recfuel - 1, d, iadd(i, 1), n, regions, delim_buf)
    end
  ) else collect_delimited_m_exh(d, i, n, regions, delim_buf)

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
macdef SIZEOF_STACKFRAME = 16

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
    val () = if not(stack_is_empty(stk)) then let
      val p_last = stack_top_last(stk)
      val () = stack_set_top_last(stk, imax(p_last, last))
    in end else ()
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

fun stack_unwind_heading_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), stk: &Buf >> _, regions: &Buf >> _, rank: int, cur_line: int, d: !Doc
): void =
  if recfuel > 0 then (
    if stack_is_empty(stk) then ()
    else let
      val top_r = stack_top_rank(stk)
    in
      if igt(top_r, 0) andalso ilt(top_r, rank) then ()
      else let
        val () = stack_pop_one(stk, regions, cur_line, d)
      in
        stack_unwind_heading_m(recfuel - 1, stk, regions, rank, cur_line, d)
      end
    end
  ) else ()

fun stack_unwind_indent_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), stk: &Buf >> _, regions: &Buf >> _, ind: int, cur_line: int, d: !Doc
): void =
  if recfuel > 0 then (
    if stack_is_empty(stk) then ()
    else let
      val top_r = stack_top_rank(stk)
      val top_i = stack_top_ind(stk)
    in
      if igt(top_r, 0) then let
        val last = stack_top_last(stk)
        val () = stack_set_top_last(stk, imax(last, cur_line))
      in
      end else if ilt(top_i, ind) then let
        val last = stack_top_last(stk)
        val () = stack_set_top_last(stk, imax(last, cur_line))
      in
      end else let
        val () = stack_pop_one(stk, regions, cur_line, d)
      in
        stack_unwind_indent_m(recfuel - 1, stk, regions, ind, cur_line, d)
      end
    end
  ) else ()

fun stack_drain_all_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), stk: &Buf >> _, regions: &Buf >> _, nlines: int, d: !Doc
): void =
  if recfuel > 0 then (
    if stack_is_empty(stk) then ()
    else let
      val () = stack_pop_one(stk, regions, nlines, d)
    in
      stack_drain_all_m(recfuel - 1, stk, regions, nlines, d)
    end
  ) else ()

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
      val () = stack_unwind_heading_m(airlock_nat(MAX_REC_FUEL), stk, regions, rank, line, d)
      val () = stack_push(stk, line, 0, rank, line)
    in
    end else let
      val empty = line_is_empty_m(airlock_nat(MAX_REC_FUEL), d, st, en)
    in
      if empty then ()
      else let
        val ind = line_visual_indent_m(airlock_nat(MAX_REC_FUEL), d, st, en, 0)
        val () = stack_unwind_indent_m(airlock_nat(MAX_REC_FUEL), stk, regions, ind, line, d)
        val () = stack_push(stk, line, ind, 0, line)
      in
      end
    end
  end
end

extern fun scan_lines_m_exh(d: !Doc, line: int, nlines: int, stk: &Buf >> _, regions: &Buf >> _, delim_buf: !Buf): void = "mac#anth_die_void"

fun scan_lines_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, line: int, nlines: int, stk: &Buf >> _, regions: &Buf >> _, delim_buf: !Buf
): void =
  if recfuel > 0 then (
    if line >= nlines then ()
    else let
      val () = process_one_line(d, line, stk, regions, delim_buf, nlines)
    in
      scan_lines_m(recfuel - 1, d, iadd(line, 1), nlines, stk, regions, delim_buf)
    end
  ) else scan_lines_m_exh(d, line, nlines, stk, regions, delim_buf)

fun regions_swap(regions: !Buf, i: int, j: int): void = let
  val o_i = fold_region_owner(regions, i)
  val e_i = fold_region_end(regions, i)
  val f_i = fold_region_offset(regions, i)
  val k_i = fold_region_kind(regions, i)
  val o_j = fold_region_owner(regions, j)
  val e_j = fold_region_end(regions, j)
  val f_j = fold_region_offset(regions, j)
  val k_j = fold_region_kind(regions, j)
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

fun regions_sort_inner_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), regions: !Buf, j: int
): void =
  if recfuel > 0 then (
    if j <= 0 then ()
    else let
      val prev = isub(j, 1)
      val o_cur = fold_region_owner(regions, j)
      val o_prev = fold_region_owner(regions, prev)
    in
      if ilt(o_cur, o_prev) then let
        val () = regions_swap(regions, prev, j)
      in
        regions_sort_inner_m(recfuel - 1, regions, prev)
      end else ()
    end
  ) else ()

fun regions_sort_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), regions: !Buf, i: int, n: int
): void =
  if recfuel > 0 then (
    if i >= n then ()
    else let
      val () = regions_sort_inner_m(airlock_nat(MAX_REC_FUEL), regions, i)
    in
      regions_sort_m(recfuel - 1, regions, iadd(i, 1), n)
    end
  ) else ()

fun regions_sort_by_owner(regions: !Buf): void =
  regions_sort_m(airlock_nat(MAX_REC_FUEL), regions, 1, fold_region_count(regions))

implement fold_region_build(d, regions) = let
  val () = buf_set_len(regions, 0)
  val nlines = doc_nlines(d)
  var delim_buf = buf_make(imax(INITIAL_BUF_BYTES, nlines))
  val () = buf_ensure(delim_buf, nlines)
  val () = buf_zero(delim_buf)
  val () = buf_set_len(delim_buf, nlines)
  val () = collect_delimited_m(airlock_nat(MAX_REC_FUEL), d, 0, doc_nnodes(d), regions, delim_buf)
  var stk = buf_make(INITIAL_STACK_BYTES)
  val () = scan_lines_m(airlock_nat(MAX_REC_FUEL), d, 0, nlines, stk, regions, delim_buf)
  val () = stack_drain_all_m(airlock_nat(MAX_REC_FUEL), stk, regions, nlines, d)
  val () = buf_free(stk)
  val () = buf_free(delim_buf)
  val () = regions_sort_by_owner(regions)
in
  fold_region_count(regions)
end

fun mark_hidden_lines_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), hidden: !Buf, line: int, finish: int
): void =
  if recfuel > 0 then (
    if line >= finish then ()
    else let
      val () = buf_set(hidden, line, 1)
    in
      mark_hidden_lines_m(recfuel - 1, hidden, iadd(line, 1), finish)
    end
  ) else ()

fun sweep_one_region(
  d: !Doc, regions: !Buf, r: int, hidden: !Buf, cover_end: &int >> _
): void = let
  val owner = fold_region_owner(regions, r)
  val fend = fold_region_end(regions, r)
  val off = fold_region_offset(regions, r)
in
  if ilt(owner, cover_end) then ()
  else if fold_has(d, off) then let
    val () = mark_hidden_lines_m(airlock_nat(MAX_REC_FUEL), hidden, iadd(owner, 1), fend)
    val () = cover_end := imax(cover_end, fend)
  in
  end else ()
end

fun sweep_regions_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, regions: !Buf, r: int, nreg: int, hidden: !Buf, cover_end: &int >> _
): void =
  if recfuel > 0 then (
    if r >= nreg then ()
    else let
      val () = sweep_one_region(d, regions, r, hidden, cover_end)
    in
      sweep_regions_m(recfuel - 1, d, regions, iadd(r, 1), nreg, hidden, cover_end)
    end
  ) else ()

implement fold_regions_compute_hidden(d, regions, hidden) = let
  val nlines = doc_nlines(d)
  val () = buf_ensure(hidden, nlines)
  val () = buf_zero(hidden)
  val () = buf_set_len(hidden, nlines)
  var cover_end: int = ~1
  val nreg = fold_region_count(regions)
in
  sweep_regions_m(airlock_nat(MAX_REC_FUEL), d, regions, 0, nreg, hidden, cover_end)
end

implement fold_region_line_hidden(hidden, line) =
  if line < 0 orelse line >= buf_len(hidden) then 0
  else buf_get(hidden, line)
