fun replace_loaded(ts: Tabs, idx: int, doc: Doc, path: Buf): Tabs = let
  var title = buf_make(REPLACE_LOADED_TITLE_INITIAL_BYTES)
  val () = base_name(path, title)
in
  tabs_replace(ts, idx, doc, path, title)
end

fun replace_image(ts: Tabs, idx: int, path: Buf): Tabs = let
  val p = buffer_c_string(path)
  val ok = fs_exists(p)
in
  if ieq(ok, 1) then let
    val doc = doc_open()
  in
    replace_loaded(ts, idx, doc, path)
  end else let
    val () = buf_free(path)
  in
    ts
  end
end

fun tabs_replace_path(ts: Tabs, idx: int, path: Buf): Tabs =
  if is_image_path(path) then replace_image(ts, idx, path)
  else let
    val doc = doc_open()
    val ok = doc_load_checked(doc, buffer_c_string(path))
  in
    if ok then replace_loaded(ts, idx, doc, path)
    else let
      val () = doc_free(doc)
      val () = buf_free(path)
    in
      ts
    end
  end

implement tabs_open_at(ts, idx, path) =
  if ige(idx, 0) andalso ilt(idx, tabs_len(ts)) then
    tabs_replace_path(ts, idx, path)
  else
    tabs_open(ts, path)


extern fun tabs_detach_fuel_exhausted(ts: Tabs, i: int): Pair = "mac#anth_die_box"

fun tabs_detach_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, i: int): Pair =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => PAIR(TNil(), TNil())
    | ~TCons(doc, path, title, sc, rest) =>
        if ieq(i, 0) then PAIR(TCons(doc, path, title, sc, TNil()), rest)
        else let
          val+ ~PAIR(one, tail) = tabs_detach_with_fuel(recfuel - 1, rest, isub(i, 1))
        in
          PAIR(one, TCons(doc, path, title, sc, tail))
        end
  ) else tabs_detach_fuel_exhausted(ts, i)

implement tabs_detach(ts, i) = tabs_detach_with_fuel(airlock_nat(MAX_REC_FUEL), ts, i)

implement tabs_link(one, ts) =
  case+ one of
  | ~TNil() => ts
  | ~TCons(doc, path, title, sc, rest) => let
      val () = tabs_free(rest)
    in
      TCons(doc, path, title, sc, ts)
    end

extern fun tabs_insert_fuel_exhausted(ts: Tabs, i: int, one: Tabs): Tabs = "mac#anth_die_box"

fun tabs_insert_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, i: int, one: Tabs): Tabs =
  if recursion_fuel_available(recfuel) then (
    if ieq(i, 0) then tabs_link(one, ts)
    else case+ ts of
      | ~TNil() => one
      | ~TCons(doc, path, title, sc, rest) => TCons(doc, path, title, sc, tabs_insert_with_fuel(recfuel - 1, rest, isub(i, 1), one))
  ) else tabs_insert_fuel_exhausted(ts, i, one)

implement tabs_insert(ts, i, one) = tabs_insert_with_fuel(airlock_nat(MAX_REC_FUEL), ts, i, one)

implement tabs_move(ts, from_i, to_i) =
  if ieq(from_i, to_i) then ts
  else let
    val n = tabs_len(ts)
  in
    if from_i >= 0 andalso from_i < n andalso to_i >= 0 andalso to_i < n then let
      val+ ~PAIR(one, rest) = tabs_detach(ts, from_i)
    in
      tabs_insert(rest, to_i, one)
    end else ts
  end

fun clone_doc(d: !Doc): Doc = let
  val d2 = doc_open()
  var text = buf_make(iadd(doc_len(d), 16))
  val () = doc_text(d, text)
  val () = doc_insert(d2, buf_ptr(text), buf_len(text))
  val () = buf_free(text)
  val () = doc_set_caret_move(d2, doc_caret(d))
  val () = doc_set_md(d2, doc_is_md(d))
in
  d2
end

fun clone_buf(src: !Buf): Buf = let
  val len = buf_len(src)
  var dst = buf_make(iadd(len, 16))
  val () = buffer_append_range(dst, src, 0, len)
  val res = dst
in
  res
end

extern fun tabs_clone_tab_fuel_exhausted(ts: Tabs, idx: int): Tabs = "mac#anth_die_box"

fun tabs_clone_tab_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), ts: Tabs, idx: int
): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) =>
        if ieq(idx, 0) then let
          val d2 = clone_doc(doc)
          val p2 = clone_buf(path)
          val t2 = clone_buf(title)
          val rest2 = tabs_append(rest, d2, p2, t2, sc)
        in
          TCons(doc, path, title, sc, rest2)
        end else let
          val rest2 = tabs_clone_tab_with_fuel(recfuel - 1, rest, isub(idx, 1))
        in
          TCons(doc, path, title, sc, rest2)
        end
  ) else tabs_clone_tab_fuel_exhausted(ts, idx)

implement tabs_clone_tab(ts, idx) = tabs_clone_tab_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx)

extern fun tabs_toggle_impl_fuel_exhausted(ts: Tabs, idx: int, ni: int): Tabs = "mac#anth_die_box"

fun tabs_toggle_impl_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int, ni: int): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = if ieq(idx, 0) andalso ige(ni, 0) then doc_toggle(doc, ni) else ()
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc, rest) else TCons(doc, path, title, sc, tabs_toggle_impl_with_fuel(recfuel - 1, rest, isub(idx, 1), ni))
      end
  ) else tabs_toggle_impl_fuel_exhausted(ts, idx, ni)

fun tabs_toggle_impl(ts: Tabs, idx: int, ni: int): Tabs = tabs_toggle_impl_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx, ni)

implement tabs_toggle(ts, idx, ni) = tabs_toggle_impl(ts, idx, ni)

extern fun tabs_toggle_deep_impl_fuel_exhausted(ts: Tabs, idx: int, ni: int): Tabs = "mac#anth_die_box"

fun tabs_toggle_deep_impl_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int, ni: int): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = if ieq(idx, 0) andalso ige(ni, 0) then doc_toggle_deep(doc, ni) else ()
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc, rest) else TCons(doc, path, title, sc, tabs_toggle_deep_impl_with_fuel(recfuel - 1, rest, isub(idx, 1), ni))
      end
  ) else tabs_toggle_deep_impl_fuel_exhausted(ts, idx, ni)

fun tabs_toggle_deep_impl(ts: Tabs, idx: int, ni: int): Tabs = tabs_toggle_deep_impl_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx, ni)

implement tabs_toggle_deep(ts, idx, ni) = tabs_toggle_deep_impl(ts, idx, ni)

extern fun tabs_toggle_task_impl_fuel_exhausted(ts: Tabs, idx: int, ni: int): Tabs = "mac#anth_die_box"

fun tabs_toggle_task_impl_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int, ni: int): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = if ieq(idx, 0) andalso ige(ni, 0) then doc_toggle_task(doc, ni) else ()
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc, rest) else TCons(doc, path, title, sc, tabs_toggle_task_impl_with_fuel(recfuel - 1, rest, isub(idx, 1), ni))
      end
  ) else tabs_toggle_task_impl_fuel_exhausted(ts, idx, ni)

fun tabs_toggle_task_impl(ts: Tabs, idx: int, ni: int): Tabs = tabs_toggle_task_impl_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx, ni)

implement tabs_toggle_task(ts, idx, ni) = tabs_toggle_task_impl(ts, idx, ni)

fun doc_jump_loc(d: !Doc, line: int, col: int): void = let
  val ls = doc_line_start(d, line)
  val caret = iadd(ls, col)
  val () = doc_reveal(d, caret)
  val () = doc_set_caret_move(d, caret)
in
end

fun tabs_jump_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int, line: int, col: int): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = if ieq(idx, 0) andalso ige(line, 0) then doc_jump_loc(doc, line, col) else ()
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc, rest)
        else TCons(doc, path, title, sc, tabs_jump_with_fuel(recfuel - 1, rest, isub(idx, 1), line, col))
      end
  ) else ts
