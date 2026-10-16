implement touch_doc(d) = doc_touch(d)

extern fun tabs_free_fuel_exhausted(ts: Tabs): void = "mac#anth_die_void"

fun tabs_free_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs): void =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => ()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = doc_free(doc)
        val () = buf_free(path)
        val () = buf_free(title)
        val () = seen_int(sc)
      in
        tabs_free_with_fuel(recfuel - 1, rest)
      end
  ) else tabs_free_fuel_exhausted(ts)

implement tabs_free(ts) = tabs_free_with_fuel(airlock_nat(MAX_REC_FUEL), ts)

extern fun tabs_len_fuel_exhausted(ts: !Tabs): int = "mac#anth_die_int"

fun tabs_len_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: !Tabs): int =
  if recfuel > 0 then (
    case+ ts of
    | @TNil() => (fold@(ts); 0)
    | @TCons(doc, _p, _t, _s, rest) => let
        val n = iadd(tabs_len_with_fuel(recfuel - 1, rest), 1)
        val () = doc_touch(doc)
      in
        fold@(ts); n
      end

  (* Yolu bos olan belge kaydedilecek bir sey olmadigi icin basarili sayilir. *)
  ) else tabs_len_fuel_exhausted(ts)

implement tabs_len(ts) = tabs_len_with_fuel(airlock_nat(MAX_REC_FUEL), ts)

fun save_ok(doc: !Doc, path: !Buf): bool =
  if is_image_path(path) then true
  else if igt(buf_len(path), 0) then let
    val ok = doc_save_physical(doc, buffer_c_string(path))
  in
    if ieq(ok, 1) then true
    else let
      val () = report_failure("doc_save", buffer_c_string(path))
    in
      false
    end
  end
  else true

(* Kayit basarisiz olursa sekme korunur: veri kaybi olmaz. *)
fun drop_head(doc: Doc, path: Buf, title: Buf, sc: int, rest: Tabs): Tabs =
  if save_ok(doc, path) then let
    val () = doc_free(doc)
    val () = buf_free(path)
    val () = buf_free(title)
    val () = seen_int(sc)
  in
    rest
  end
  else TCons(doc, path, title, sc, rest)

extern fun tabs_drop_fuel_exhausted(ts: Tabs, i: int): Tabs = "mac#anth_die_box"

fun tabs_drop_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, i: int): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) =>
        if ieq(i, 0) then drop_head(doc, path, title, sc, rest)
        else TCons(doc, path, title, sc, tabs_drop_with_fuel(recfuel - 1, rest, isub(i, 1)))
  ) else tabs_drop_fuel_exhausted(ts, i)

implement tabs_drop(ts, i) = tabs_drop_with_fuel(airlock_nat(MAX_REC_FUEL), ts, i)

extern fun tabs_append_impl_fuel_exhausted(ts: Tabs, doc: Doc, path: Buf, title: Buf, sc: int): Tabs = "mac#anth_die_box"

fun tabs_append_impl_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, doc: Doc, path: Buf, title: Buf, sc: int): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => TCons(doc, path, title, sc, TNil())
    | ~TCons(d, p, t, s, rest) => TCons(d, p, t, s, tabs_append_impl_with_fuel(recfuel - 1, rest, doc, path, title, sc))
  ) else tabs_append_impl_fuel_exhausted(ts, doc, path, title, sc)

fun tabs_append_impl(ts: Tabs, doc: Doc, path: Buf, title: Buf, sc: int): Tabs = tabs_append_impl_with_fuel(airlock_nat(MAX_REC_FUEL), ts, doc, path, title, sc)

implement tabs_append(ts, doc, path, title, sc) =
  tabs_append_impl(ts, doc, path, title, sc)

implement tabs_add(ts, doc, path, title) =
  tabs_append_impl(ts, doc, path, title, 0)

extern fun tabs_replace_fuel_exhausted(ts: Tabs, idx: int, doc: Doc, path: Buf, title: Buf): Tabs = "mac#anth_die_box"

fun tabs_replace_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), ts: Tabs, idx: int, doc: Doc, path: Buf, title: Buf
): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => TCons(doc, path, title, 0, TNil())
    | ~TCons(d, p, t, sc, rest) =>
        if ieq(idx, 0) then let
          val () = doc_free(d)
          val () = buf_free(p)
          val () = buf_free(t)
          val () = seen_int(sc)
        in
          TCons(doc, path, title, 0, rest)
        end else
          TCons(d, p, t, sc, tabs_replace_with_fuel(recfuel - 1, rest, isub(idx, 1), doc, path, title))
  ) else tabs_replace_fuel_exhausted(ts, idx, doc, path, title)

implement tabs_replace(ts, idx, doc, path, title) =
  tabs_replace_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx, doc, path, title)

macdef PAGE_STEP_LINES = 15
macdef INDENT_TEXT = "  "
macdef BOLD_MARK = "**"
macdef ITALIC_MARK = "*"
macdef WIKILINK_OPEN = "[["
macdef WIKILINK_CLOSE = "]]"

fun select_all(d: !Doc): void = let
  val () = doc_set_caret_move(d, 0)
in
  doc_set_caret_extend(d, doc_len(d))
end

fun delete_selection(d: !Doc): void =
  if ine(doc_caret(d), doc_anchor(d)) then doc_delete(d) else ()

fun wrap_selection(d: !Doc, open_mark: string, close_mark: string): void =
  doc_wrap(d, open_mark, c_strlen(open_mark), close_mark, c_strlen(close_mark))

fun is_ar_byte(b: int): bool =
  b >= 216 andalso b <= 219

fun doc_caret_is_ar(d: !Doc): bool = let
  val c = doc_caret(d)
  val len = doc_len(d)
in
  if len <= 0 then false
  else let
    val b0 = if c < len then doc_byte(d, c) else 0
    val b1 = if c > 0 then doc_byte(d, isub(c, 1)) else 0
    val b2 = if c > 1 then doc_byte(d, isub(c, 2)) else 0
  in
    is_ar_byte(b0) orelse is_ar_byte(b1) orelse is_ar_byte(b2)
  end
end

fun caret_move_h(d: !Doc, is_left: bool): void =
  if doc_caret_is_ar(d) then (if is_left then doc_right_move(d) else doc_left_move(d))
  else (if is_left then doc_left_move(d) else doc_right_move(d))

fun caret_select_h(d: !Doc, is_left: bool): void =
  if doc_caret_is_ar(d) then (if is_left then doc_right_select(d) else doc_left_select(d))
  else (if is_left then doc_left_select(d) else doc_right_select(d))

fun run_caret_motion_cmd(d: !Doc, cmd: Cmd): void =
  if is_cmd(cmd, CMD_CARET_LEFT) then caret_move_h(d, true)
  else if is_cmd(cmd, CMD_CARET_RIGHT) then caret_move_h(d, false)
  else if is_cmd(cmd, CMD_CARET_UP) then doc_up_move(d)
  else if is_cmd(cmd, CMD_CARET_DOWN) then doc_down_move(d)
  else if is_cmd(cmd, CMD_CARET_LINE_START) then doc_home_move(d)
  else if is_cmd(cmd, CMD_CARET_LINE_END) then doc_end_move(d)
  else if is_cmd(cmd, CMD_WORD_LEFT) then doc_word_left_move(d)
  else if is_cmd(cmd, CMD_WORD_RIGHT) then doc_word_right_move(d)
  else if is_cmd(cmd, CMD_DOC_START) then doc_doc_start_move(d)
  else if is_cmd(cmd, CMD_DOC_END) then doc_doc_end_move(d)
  else if is_cmd(cmd, CMD_PAGE_UP) then doc_page_up_move(d, PAGE_STEP_LINES)
  else if is_cmd(cmd, CMD_PAGE_DOWN) then doc_page_down_move(d, PAGE_STEP_LINES)
  else ()

fun run_select_motion_cmd(d: !Doc, cmd: Cmd): void =
  if is_cmd(cmd, CMD_SELECT_ALL) then select_all(d)
  else if is_cmd(cmd, CMD_COLLAPSE_SELECTION) then doc_set_caret_move(d, doc_caret(d))
  else if is_cmd(cmd, CMD_SELECT_LEFT) then caret_select_h(d, true)
  else if is_cmd(cmd, CMD_SELECT_RIGHT) then caret_select_h(d, false)
  else if is_cmd(cmd, CMD_SELECT_UP) then doc_up_select(d)
  else if is_cmd(cmd, CMD_SELECT_DOWN) then doc_down_select(d)
  else if is_cmd(cmd, CMD_SELECT_LINE_START) then doc_home_select(d)
  else if is_cmd(cmd, CMD_SELECT_LINE_END) then doc_end_select(d)
  else if is_cmd(cmd, CMD_SELECT_WORD_LEFT) then doc_word_left_select(d)
  else if is_cmd(cmd, CMD_SELECT_WORD_RIGHT) then doc_word_right_select(d)
  else if is_cmd(cmd, CMD_SELECT_DOC_START) then doc_doc_start_select(d)
  else if is_cmd(cmd, CMD_SELECT_DOC_END) then doc_doc_end_select(d)
  else if is_cmd(cmd, CMD_SELECT_PAGE_UP) then doc_page_up_select(d, PAGE_STEP_LINES)
  else if is_cmd(cmd, CMD_SELECT_PAGE_DOWN) then doc_page_down_select(d, PAGE_STEP_LINES)
  else ()

fun run_motion_cmd(d: !Doc, cmd: Cmd): void = let
  val () = run_caret_motion_cmd(d, cmd)
in
  run_select_motion_cmd(d, cmd)
end

fun run_edit_cmd(d: !Doc, cmd: Cmd): void =
  if is_cmd(cmd, CMD_BACKSPACE) then doc_backspace(d)
  else if is_cmd(cmd, CMD_DELETE) then doc_delete(d)
  else if is_cmd(cmd, CMD_DELETE_SELECTION) then delete_selection(d)
  else if is_cmd(cmd, CMD_DELETE_WORD_LEFT) then doc_del_word_left(d)
  else if is_cmd(cmd, CMD_DELETE_WORD_RIGHT) then doc_del_word_right(d)
  else if is_cmd(cmd, CMD_UNDO) then doc_undo(d)
  else if is_cmd(cmd, CMD_REDO) then doc_redo(d)
  else if is_cmd(cmd, CMD_WRAP_BOLD) then wrap_selection(d, BOLD_MARK, BOLD_MARK)
  else if is_cmd(cmd, CMD_WRAP_ITALIC) then wrap_selection(d, ITALIC_MARK, ITALIC_MARK)
  else if is_cmd(cmd, CMD_WRAP_WIKILINK) then wrap_selection(d, WIKILINK_OPEN, WIKILINK_CLOSE)
  else if is_cmd(cmd, CMD_INDENT) then doc_insert(d, c_str_ptr(INDENT_TEXT), c_strlen(INDENT_TEXT))
  else ()

