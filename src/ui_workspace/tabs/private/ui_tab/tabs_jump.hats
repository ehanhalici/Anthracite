implement tabs_jump(ts, idx, line, col) = tabs_jump_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx, line, col)

fun tabs_find_doc_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: !Tabs, idx: int, q: !Buf, from: int, dir: int): int =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | TNil() => ~1
    | TCons(doc, path, title, sc, rest) =>
        if ieq(idx, 0) then ix_doc_find(doc, q, from, dir)
        else tabs_find_doc_with_fuel(recfuel - 1, rest, isub(idx, 1), q, from, dir)
  ) else ~1

implement tabs_find_doc(ts, idx, q, from, dir) = tabs_find_doc_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx, q, from, dir)

fun doc_select_rng(doc: !Doc, st: int, en: int): void = let
  val () = doc_reveal(doc, st)
  val () = doc_set_caret_move(doc, st)
  val () = doc_set_caret_extend(doc, en)
in
end

fun tabs_select_range_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int, st: int, en: int): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = if ieq(idx, 0) andalso ige(st, 0) then doc_select_rng(doc, st, en) else ()
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc, rest)
        else TCons(doc, path, title, sc, tabs_select_range_with_fuel(recfuel - 1, rest, isub(idx, 1), st, en))
      end
  ) else ts

implement tabs_select_range(ts, idx, st, en) = tabs_select_range_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx, st, en)

fun tabs_find_path_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: !Tabs, p: !Buf, cur: int): int =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | TNil() => ~1
    | TCons(doc, path, title, sc, rest) => let
        val found = ieq(c_strcmp(buffer_c_string(path), buffer_c_string(p)), 0)
      in
        if found then cur
        else tabs_find_path_with_fuel(recfuel - 1, rest, p, iadd(cur, 1))
      end
  ) else ~1

implement tabs_find_path(ts, p) = tabs_find_path_with_fuel(airlock_nat(MAX_REC_FUEL), ts, p, 0)

fun tabs_caret_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: !Tabs, idx: int): int =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | TNil() => 0
    | TCons(doc, path, title, sc, rest) =>
        if ieq(idx, 0) then doc_caret(doc)
        else tabs_caret_with_fuel(recfuel - 1, rest, isub(idx, 1))
  ) else 0

implement tabs_caret(ts, idx) = tabs_caret_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx)

fun tabs_copy_doc_text_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: !Tabs, p: !Buf, dst: &Buf >> _): int =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | TNil() => 0
    | TCons(doc, path, title, sc, rest) =>
        if ieq(c_strcmp(buffer_c_string(path), buffer_c_string(p)), 0) then let
          val dlen = doc_len(doc)
          val () = buf_ensure(dst, iadd(dlen, 2))
          val cap = buf_cap(dst)
          val n = doc_slice_buf(doc, 0, dlen, dst, cap)
          val () = buf_set_len(dst, n)
        in
          1
        end
        else tabs_copy_doc_text_with_fuel(recfuel - 1, rest, p, dst)
  ) else 0

implement tabs_copy_doc_text(ts, p, dst) = tabs_copy_doc_text_with_fuel(airlock_nat(MAX_REC_FUEL), ts, p, dst)
