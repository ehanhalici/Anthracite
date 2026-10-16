fun doc_insert_reparse(d: !Doc, at: int, n: int, old: int, delta: int): void = let
  val () = lines_apply_edit(d, at, 0, n)
  val () = folds_apply_edit(d, at, 0, n)
  val () = ast_reparse_v2(d, at, 0, n)
  val () = seen_int(old); val () = seen_int(delta)
in
  fold_apply(d)
end

fun doc_insert_core(d: !Doc, p: ptr, n: int): void = let
  var a: int = 0
  var b: int = 0
  val () = sel_span(d, a, b)
  val () = if igt(b, a) then remove_between(d, a, b) else ()
  val at = d_caret(d)
  val old = d_len(d)
  val () = gap_move(d, at)
  val () = gap_put(d, p, n)
  val () = d_set_caret(d, iadd(at, n))
  val () = d_set_anchor(d, iadd(at, n))
  val () = d_bump_ver(d)
  val () = fold_shift(d, at, n)
in
  doc_insert_reparse(d, at, n, old, isub(d_len(d), old))
end

implement doc_insert(d, p, n) = let
  val () = if ieq(n, 1) then let
      val b = mem_byte(p, 1, 0)
    in
      if ieq(b, 32) orelse ieq(b, 10) then doc_record(d, OpBreak) else doc_record(d, OpChar)
    end else doc_record(d, OpBreak)
in
  doc_insert_core(d, p, n)
end

implement doc_insert_buf(d, src, n) =
  doc_insert(d, buf_ptr(src), n)

extern fun utf8_back_fuel_exhausted(d: !Doc, k: int, limit: int): int = "mac#anth_die_int"

fun utf8_back {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, k: int, limit: int): int =
  if recursion_fuel_available(recfuel) then (
    if ile(k, 0) then 0
    else if ile(limit, 0) then k
    else let
      val b = doc_byte(d, isub(k, 1))
    in
      if b < 128 orelse b >= 192 then isub(k, 1)
      else utf8_back(recfuel - 1, d, isub(k, 1), isub(limit, 1))
    end
  ) else utf8_back_fuel_exhausted(d, k, limit)

fun utf8_prev(d: !Doc, i: int): int =
  if ile(i, 1) then 0
  else utf8_back(airlock_nat(MAX_REC_FUEL), d, i, 4)

fun utf8_align(d: !Doc, i: int): int =
  if ile(i, 0) then 0
  else if ige(i, d_len(d)) then d_len(d)
  else let
    val b = doc_byte(d, i)
  in
    if b < 128 orelse b >= 192 then i
    else utf8_prev(d, iadd(i, 1))
  end

fun utf8_next(d: !Doc, i: int): int = let
  val len = d_len(d)
in
  if ige(i, len) then len
  else let
    val b = doc_byte(d, i)
    val s = if ilt(b, 128) then 1 else if ilt(b, 224) then 2 else if ilt(b, 240) then 3 else 4
    val j = iadd(i, s)
  in
    if igt(j, len) then len else j
  end
end

implement doc_delete_range(d, start, finish) = let
  val a=imax(0,imin(doc_len(d),start))
  val b=imax(a,imin(doc_len(d),finish))
in if igt(b,a) then let val ()=doc_record(d,OpBreak)
  in remove_between(d,a,b) end else () end

implement doc_backspace(d) = let
  val () = doc_record(d, OpBreak)
  var a: int = 0
  var b: int = 0
  val () = sel_span(d, a, b)
in
  if igt(b, a) then remove_between(d, a, b)
  else let
    val c = d_caret(d)
  in
    if c <= 0 then () else remove_between(d, utf8_prev(d, c), c)
  end
end

implement doc_delete(d) = let
  val () = doc_record(d, OpBreak)
  var a: int = 0
  var b: int = 0
  val () = sel_span(d, a, b)
in
  if igt(b, a) then remove_between(d, a, b)
  else let
    val c = d_caret(d)
    val n = utf8_next(d, c)
  in
    if ile(n, c) then () else remove_between(d, c, n)
  end
end

implement doc_set_caret_move(d, i) = let
  val len = d_len(d)
  val c = if i < 0 then 0 else if i > len then len else i
  val () = d_set_caret(d, c)
in
  d_set_anchor(d, c)
end

implement doc_set_caret_extend(d, i) = let
  val len = d_len(d)
  val c = if i < 0 then 0 else if i > len then len else i
in
  d_set_caret(d, c)
end

fun doc_left_target(d: !Doc, keep: Toggle): int = let
  val c = d_caret(d)
  val a = d_anchor(d)
in
  if is_off(keep) andalso ine(c, a) then imin(c, a) else utf8_prev(d, c)
end

fun doc_right_target(d: !Doc, keep: Toggle): int = let
  val c = d_caret(d)
  val a = d_anchor(d)
in
  if is_off(keep) andalso ine(c, a) then imax(c, a) else utf8_next(d, c)
end

implement doc_left_move(d) = doc_set_caret_move(d, doc_left_target(d, Off))
implement doc_left_select(d) = doc_set_caret_extend(d, doc_left_target(d, On))

implement doc_right_move(d) = doc_set_caret_move(d, doc_right_target(d, Off))
implement doc_right_select(d) = doc_set_caret_extend(d, doc_right_target(d, On))

fun doc_home_target(d: !Doc): int =
  doc_line_start(d, doc_line_of(d, d_caret(d)))

fun doc_end_target(d: !Doc): int = let
  val line = doc_line_of(d, d_caret(d))
  val n = d_nlines(d)
  val e = if iadd(line, 1) >= n then d_len(d) else doc_line_start(d, iadd(line, 1))
in
  if igt(e, 0) andalso ieq(doc_byte(d, isub(e, 1)), CHAR_LF) then isub(e, 1) else e
end

implement doc_home_move(d) = doc_set_caret_move(d, doc_home_target(d))
implement doc_home_select(d) = doc_set_caret_extend(d, doc_home_target(d))

implement doc_end_move(d) = doc_set_caret_move(d, doc_end_target(d))
implement doc_end_select(d) = doc_set_caret_extend(d, doc_end_target(d))

fun prev_line_target(d: !Doc, prev: int, ls: int, col_cps: int, wc: int): int = let
  val st = doc_line_start(d, prev)
  val stop = if igt(ls, st) andalso ieq(doc_byte(d, isub(ls, 1)), CHAR_LF) then isub(ls, 1) else ls
  val plen_cps = doc_codepoints(d, st, stop)
  val prow = (if wc > 0 andalso igt(plen_cps, wc) then idiv(isub(plen_cps, 1), wc) else 0) : int
  val target_cps = imin(plen_cps, iadd(imul(prow, wc), col_cps))
in
  doc_advance_cps(d, st, stop, target_cps)
end

fun doc_up_target(d: !Doc): int = let
  val c = d_caret(d)
  val line = doc_line_of(d, c)
  val ls = doc_line_start(d, line)
  val cur_cps = doc_codepoints(d, ls, c)
  val wc = doc_get_wrap(d)
  val col_cps = (if wc > 0 then imod(cur_cps, wc) else cur_cps) : int
in
  if wc > 0 andalso ige(cur_cps, wc) then
    doc_advance_cps(d, ls, c, isub(cur_cps, wc))
  else if line <= 0 then 0
  else prev_line_target(d, isub(line, 1), ls, col_cps, wc)
end

fun next_line_target(d: !Doc, n: int, next_line: int, col_cps: int, wc: int): int = let
  val st = doc_line_start(d, next_line)
  val en = if iadd(next_line, 1) >= n then d_len(d) else doc_line_start(d, iadd(next_line, 1))
  val stop = if igt(en, st) andalso ieq(doc_byte(d, isub(en, 1)), CHAR_LF) then isub(en, 1) else en
  val nlen_cps = doc_codepoints(d, st, stop)
  val target_cps = imin(nlen_cps, col_cps)
in
  doc_advance_cps(d, st, stop, target_cps)
end
