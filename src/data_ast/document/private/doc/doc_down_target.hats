fun doc_down_target(d: !Doc): int = let
  val c = d_caret(d)
  val line = doc_line_of(d, c)
  val n = d_nlines(d)
  val ls = doc_line_start(d, line)
  val en0 = if iadd(line, 1) < n then doc_line_start(d, iadd(line, 1)) else d_len(d)
  val stop0 = if igt(en0, ls) andalso ieq(doc_byte(d, isub(en0, 1)), CHAR_LF) then isub(en0, 1) else en0
  val total_cps = doc_codepoints(d, ls, stop0)
  val cur_cps = doc_codepoints(d, ls, c)
  val wc = doc_get_wrap(d)
  val col_cps = (if wc > 0 then imod(cur_cps, wc) else cur_cps) : int
  val down_cps = iadd(cur_cps, wc)
in
  if wc > 0 andalso ilt(down_cps, total_cps) then
    doc_advance_cps(d, ls, stop0, down_cps)
  else if iadd(line, 1) >= n then d_len(d)
  else next_line_target(d, n, iadd(line, 1), col_cps, wc)
end

implement doc_up_move(d) = doc_set_caret_move(d, doc_up_target(d))
implement doc_up_select(d) = doc_set_caret_extend(d, doc_up_target(d))
implement doc_down_move(d) = doc_set_caret_move(d, doc_down_target(d))
implement doc_down_select(d) = doc_set_caret_extend(d, doc_down_target(d))

datatype CharClass = ClassBlank | ClassWord | ClassOther

fun class_code(c: CharClass): int = case+ c of
  | ClassBlank() => 0
  | ClassWord() => 1
  | ClassOther() => 2

fun is_class(a: CharClass, b: CharClass): bool = class_code(a) = class_code(b)

fun doc_char_class(b: int): CharClass =
  if b <= 32 then ClassBlank()
  else if (b >= 97 andalso b <= 122) orelse (b >= 65 andalso b <= 90) orelse (b >= 48 andalso b <= 57) orelse (b >= 128) then ClassWord()
  else ClassOther()

extern fun blank_back_fuel_exhausted(d: !Doc, i: int): int = "mac#anth_die_int"

fun blank_back_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int): int =
  if recursion_fuel_available(recfuel) then (
    if i > 0 andalso is_class(doc_char_class(doc_byte(d, isub(i, 1))), ClassBlank) then
      blank_back_with_fuel(recfuel - 1, d, utf8_prev(d, i))
    else i
  ) else blank_back_fuel_exhausted(d, i)

extern fun class_back_fuel_exhausted(d: !Doc, i: int, cls: CharClass): int = "mac#anth_die_int"

fun class_back_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, cls: CharClass): int =
  if recursion_fuel_available(recfuel) then (
    if i > 0 andalso is_class(doc_char_class(doc_byte(d, isub(i, 1))), cls) then
      class_back_with_fuel(recfuel - 1, d, utf8_prev(d, i), cls)
    else i
  ) else class_back_fuel_exhausted(d, i, cls)

fun word_left_pos(d: !Doc, cur: int): int =
  if cur <= 0 then 0
  else let
    val i = blank_back_with_fuel(airlock_nat(MAX_REC_FUEL), d, cur)
  in
    if i > 0 then class_back_with_fuel(airlock_nat(MAX_REC_FUEL), d, i, doc_char_class(doc_byte(d, isub(i, 1)))) else i
  end

extern fun skip_class_run_fuel_exhausted(d: !Doc, i: int, len: int, cls: CharClass): int = "mac#anth_die_int"

fun skip_class_run_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, len: int, cls: CharClass): int =
  if recursion_fuel_available(recfuel) then (
    if ilt(i, len) andalso is_class(doc_char_class(doc_byte(d, i)), cls) then skip_class_run_with_fuel(recfuel - 1, d, utf8_next(d, i), len, cls)
    else i
  ) else skip_class_run_fuel_exhausted(d, i, len, cls)

fun skip_class_run(d: !Doc, i: int, len: int, cls: CharClass): int = skip_class_run_with_fuel(airlock_nat(MAX_REC_FUEL), d, i, len, cls)

extern fun skip_blank_run_fuel_exhausted(d: !Doc, i: int, len: int): int = "mac#anth_die_int"

fun skip_blank_run_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, len: int): int =
  if recursion_fuel_available(recfuel) then (
    if ilt(i, len) andalso is_class(doc_char_class(doc_byte(d, i)), ClassBlank) andalso ine(doc_byte(d, i), CHAR_LF) then skip_blank_run_with_fuel(recfuel - 1, d, utf8_next(d, i), len)
    else i
  ) else skip_blank_run_fuel_exhausted(d, i, len)

fun skip_blank_run(d: !Doc, i: int, len: int): int = skip_blank_run_with_fuel(airlock_nat(MAX_REC_FUEL), d, i, len)

fun word_right_pos(d: !Doc, cur: int): int = let
  val len = d_len(d)
in
  if cur >= len then len
  else let
    val cls = doc_char_class(doc_byte(d, cur))
  in
    if is_class(cls, ClassBlank) then skip_class_run(d, cur, len, ClassBlank)
    else skip_blank_run(d, skip_class_run(d, cur, len, cls), len)
  end
end

implement doc_word_left_move(d) = let
  val c = d_caret(d)
  val target = word_left_pos(d, c)
in
  doc_set_caret_move(d, target)
end

implement doc_word_left_select(d) = let
  val c = d_caret(d)
  val target = word_left_pos(d, c)
in
  doc_set_caret_extend(d, target)
end

implement doc_word_right_move(d) = let
  val c = d_caret(d)
  val target = word_right_pos(d, c)
in
  doc_set_caret_move(d, target)
end

implement doc_word_right_select(d) = let
  val c = d_caret(d)
  val target = word_right_pos(d, c)
in
  doc_set_caret_extend(d, target)
end

implement doc_del_word_left(d) = let
  val () = doc_record(d, OpBreak)
  var a: int = 0
  var b: int = 0
  val () = sel_span(d, a, b)
in
  if igt(b, a) then remove_between(d, a, b)
  else let
    val c = d_caret(d)
    val target = word_left_pos(d, c)
  in
    if target < c then remove_between(d, target, c) else ()
  end
end

implement doc_del_word_right(d) = let
  val () = doc_record(d, OpBreak)
  var a: int = 0
  var b: int = 0
  val () = sel_span(d, a, b)
in
  if igt(b, a) then remove_between(d, a, b)
  else let
    val c = d_caret(d)
    val target = word_right_pos(d, c)
  in
    if target > c then remove_between(d, c, target) else ()
  end
end

implement doc_doc_start_move(d) = doc_set_caret_move(d, 0)
implement doc_doc_start_select(d) = doc_set_caret_extend(d, 0)

implement doc_doc_end_move(d) = doc_set_caret_move(d, d_len(d))
implement doc_doc_end_select(d) = doc_set_caret_extend(d, d_len(d))

extern fun page_up_move_fuel_exhausted(d: !Doc, k: int, nlines: int): void = "mac#anth_die_void"

fun page_up_move_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, k: int, nlines: int): void =
  if recursion_fuel_available(recfuel) then (
    if k < nlines then let
      val () = doc_up_move(d)
    in
      page_up_move_with_fuel(recfuel - 1, d, iadd(k, 1), nlines)
    end else ()
  ) else page_up_move_fuel_exhausted(d, k, nlines)

implement doc_page_up_move(d, nlines) = page_up_move_with_fuel(airlock_nat(MAX_REC_FUEL), d, 0, nlines)

extern fun page_up_select_fuel_exhausted(d: !Doc, k: int, nlines: int): void = "mac#anth_die_void"

fun page_up_select_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, k: int, nlines: int): void =
  if recursion_fuel_available(recfuel) then (
    if k < nlines then let
      val () = doc_up_select(d)
    in
      page_up_select_with_fuel(recfuel - 1, d, iadd(k, 1), nlines)
    end else ()
  ) else page_up_select_fuel_exhausted(d, k, nlines)

implement doc_page_up_select(d, nlines) = page_up_select_with_fuel(airlock_nat(MAX_REC_FUEL), d, 0, nlines)

extern fun page_down_move_fuel_exhausted(d: !Doc, k: int, nlines: int): void = "mac#anth_die_void"

fun page_down_move_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, k: int, nlines: int): void =
  if recursion_fuel_available(recfuel) then (
    if k < nlines then let
      val () = doc_down_move(d)
    in
      page_down_move_with_fuel(recfuel - 1, d, iadd(k, 1), nlines)
    end else ()
  ) else page_down_move_fuel_exhausted(d, k, nlines)

implement doc_page_down_move(d, nlines) = page_down_move_with_fuel(airlock_nat(MAX_REC_FUEL), d, 0, nlines)

extern fun page_down_select_fuel_exhausted(d: !Doc, k: int, nlines: int): void = "mac#anth_die_void"
