#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "mem.sats"
staload "os/fs.sats"
staload "data_ast/doc.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/ui_tab.sats"
staload "ui_workspace/ui_cmd.sats"

#include "common.hats"

implement touch_doc(d) = doc_len(d)

implement tabs_free(ts) =
  case+ ts of
  | ~TNil() => ()
  | ~TCons(doc, path, title, sc, rest) => let
      val () = doc_free(doc)
      val () = buf_free(path)
      val () = buf_free(title)
      val _u = sc
    in
      tabs_free(rest)
    end

implement tabs_len(ts) =
  case+ ts of
  | @TNil() => (fold@(ts); 0)
  | @TCons(doc, _p, _t, _s, rest) => let
      val n = iadd(tabs_len(rest), 1)
      val _u = doc_len(doc)
    in
      fold@(ts); n
    end

implement tabs_drop(ts, i) =
  case+ ts of
  | ~TNil() => TNil()
  | ~TCons(doc, path, title, sc, rest) =>
      if ieq(i, 0) then let
        val () = if igt(buf_len(path), 0) then let
          val p = cstr(path)
          val _s = doc_save_physical(doc, p)
        in
        end else ()
        val () = doc_free(doc)
        val () = buf_free(path)
        val () = buf_free(title)
        val _u = sc
      in
        rest
      end else TCons(doc, path, title, sc, tabs_drop(rest, isub(i, 1)))

fun tabs_append_impl(ts: Tabs, doc: Doc, path: Buf, title: Buf, sc: int): Tabs =
  case+ ts of
  | ~TNil() => TCons(doc, path, title, sc, TNil())
  | ~TCons(d, p, t, s, rest) => TCons(d, p, t, s, tabs_append_impl(rest, doc, path, title, sc))

implement tabs_append(ts, doc, path, title, sc) =
  tabs_append_impl(ts, doc, path, title, sc)

implement tabs_add(ts, doc, path, title) =
  tabs_append_impl(ts, doc, path, title, 0)

macdef MOVE_CARET = 0
macdef EXTEND_SELECTION = 1
macdef PAGE_STEP_LINES = 15
macdef INDENT_TEXT = "  "
macdef BOLD_MARK = "**"
macdef ITALIC_MARK = "*"
macdef WIKILINK_OPEN = "[["
macdef WIKILINK_CLOSE = "]]"

fun select_all(d: !Doc): void = let
  val () = doc_set_caret(d, 0, MOVE_CARET)
in
  doc_set_caret(d, doc_len(d), EXTEND_SELECTION)
end

fun delete_selection(d: !Doc): void =
  if ine(doc_caret(d), doc_anchor(d)) then doc_delete(d) else ()

fun wrap_selection(d: !Doc, open_mark: string, close_mark: string): void =
  doc_wrap(d, open_mark, c_strlen(open_mark), close_mark, c_strlen(close_mark))

fun run_motion_cmd(d: !Doc, cmd: int): void =
  if ieq(cmd, CMD_CARET_LEFT) then doc_left(d)
  else if ieq(cmd, CMD_CARET_RIGHT) then doc_right(d)
  else if ieq(cmd, CMD_CARET_UP) then doc_up(d)
  else if ieq(cmd, CMD_CARET_DOWN) then doc_down(d)
  else if ieq(cmd, CMD_CARET_LINE_START) then doc_home(d)
  else if ieq(cmd, CMD_CARET_LINE_END) then doc_end(d)
  else if ieq(cmd, CMD_SELECT_ALL) then select_all(d)
  else if ieq(cmd, CMD_COLLAPSE_SELECTION) then doc_set_caret(d, doc_caret(d), MOVE_CARET)
  else if ieq(cmd, CMD_SELECT_LEFT) then doc_left_k(d, EXTEND_SELECTION)
  else if ieq(cmd, CMD_SELECT_RIGHT) then doc_right_k(d, EXTEND_SELECTION)
  else if ieq(cmd, CMD_SELECT_UP) then doc_up_k(d, EXTEND_SELECTION)
  else if ieq(cmd, CMD_SELECT_DOWN) then doc_down_k(d, EXTEND_SELECTION)
  else if ieq(cmd, CMD_SELECT_LINE_START) then doc_home_k(d, EXTEND_SELECTION)
  else if ieq(cmd, CMD_SELECT_LINE_END) then doc_end_k(d, EXTEND_SELECTION)
  else if ieq(cmd, CMD_WORD_LEFT) then doc_word_left(d, MOVE_CARET)
  else if ieq(cmd, CMD_WORD_RIGHT) then doc_word_right(d, MOVE_CARET)
  else if ieq(cmd, CMD_SELECT_WORD_LEFT) then doc_word_left(d, EXTEND_SELECTION)
  else if ieq(cmd, CMD_SELECT_WORD_RIGHT) then doc_word_right(d, EXTEND_SELECTION)
  else if ieq(cmd, CMD_DOC_START) then doc_doc_start(d, MOVE_CARET)
  else if ieq(cmd, CMD_DOC_END) then doc_doc_end(d, MOVE_CARET)
  else if ieq(cmd, CMD_SELECT_DOC_START) then doc_doc_start(d, EXTEND_SELECTION)
  else if ieq(cmd, CMD_SELECT_DOC_END) then doc_doc_end(d, EXTEND_SELECTION)
  else if ieq(cmd, CMD_PAGE_UP) then doc_page_up(d, PAGE_STEP_LINES, MOVE_CARET)
  else if ieq(cmd, CMD_PAGE_DOWN) then doc_page_down(d, PAGE_STEP_LINES, MOVE_CARET)
  else if ieq(cmd, CMD_SELECT_PAGE_UP) then doc_page_up(d, PAGE_STEP_LINES, EXTEND_SELECTION)
  else if ieq(cmd, CMD_SELECT_PAGE_DOWN) then doc_page_down(d, PAGE_STEP_LINES, EXTEND_SELECTION)
  else ()

fun run_edit_cmd(d: !Doc, cmd: int): void =
  if ieq(cmd, CMD_BACKSPACE) then doc_backspace(d)
  else if ieq(cmd, CMD_DELETE) then doc_delete(d)
  else if ieq(cmd, CMD_DELETE_SELECTION) then delete_selection(d)
  else if ieq(cmd, CMD_DELETE_WORD_LEFT) then doc_del_word_left(d)
  else if ieq(cmd, CMD_DELETE_WORD_RIGHT) then doc_del_word_right(d)
  else if ieq(cmd, CMD_UNDO) then doc_undo(d)
  else if ieq(cmd, CMD_REDO) then doc_redo(d)
  else if ieq(cmd, CMD_WRAP_BOLD) then wrap_selection(d, BOLD_MARK, BOLD_MARK)
  else if ieq(cmd, CMD_WRAP_ITALIC) then wrap_selection(d, ITALIC_MARK, ITALIC_MARK)
  else if ieq(cmd, CMD_WRAP_WIKILINK) then wrap_selection(d, WIKILINK_OPEN, WIKILINK_CLOSE)
  else if ieq(cmd, CMD_INDENT) then doc_insert(d, c_str_ptr(INDENT_TEXT), c_strlen(INDENT_TEXT))
  else ()

fun run_cmd(d: !Doc, cmd: int): void = let
  val () = run_motion_cmd(d, cmd)
in
  run_edit_cmd(d, cmd)
end

fun tabs_cmd_impl(ts: Tabs, idx: int, cmd: int): Tabs =
  case+ ts of
  | ~TNil() => TNil()
  | ~TCons(doc, path, title, sc, rest) => let
      val () = if ieq(idx, 0) then run_cmd(doc, cmd) else ()
    in
      TCons(doc, path, title, sc, cmd_rest(ieq(idx, 0), rest, idx, cmd))
    end
and cmd_rest(stop: bool, rest: Tabs, idx: int, cmd: int): Tabs =
  if stop then rest else tabs_cmd_impl(rest, isub(idx, 1), cmd)

implement tabs_cmd(ts, idx, cmd) = tabs_cmd_impl(ts, idx, cmd)

fun tabs_ins_impl(ts: Tabs, idx: int, p: ptr, n: int): Tabs =
  case+ ts of
  | ~TNil() => TNil()
  | ~TCons(doc, path, title, sc, rest) => let
      val () = if ieq(idx, 0) andalso igt(n, 0) then doc_insert(doc, p, n) else ()
    in
      TCons(doc, path, title, sc, ins_rest(ieq(idx, 0), rest, idx, p, n))
    end
and ins_rest(stop: bool, rest: Tabs, idx: int, p: ptr, n: int): Tabs =
  if stop then rest else tabs_ins_impl(rest, isub(idx, 1), p, n)

implement tabs_ins(ts, idx, p, n) = tabs_ins_impl(ts, idx, p, n)

fun tabs_scroll_impl(ts: Tabs, idx: int, dv: int, lim: int): Tabs =
  case+ ts of
  | ~TNil() => TNil()
  | ~TCons(doc, path, title, sc, rest) => let
      val sc2 = if ieq(idx, 0) then imax(0, imin(lim, iadd(sc, dv))) else sc
    in
      TCons(doc, path, title, sc2, scroll_rest(ieq(idx, 0), rest, idx, dv, lim))
    end
and scroll_rest(stop: bool, rest: Tabs, idx: int, dv: int, lim: int): Tabs =
  if stop then rest else tabs_scroll_impl(rest, isub(idx, 1), dv, lim)

implement tabs_scroll(ts, idx, dv, lim) = tabs_scroll_impl(ts, idx, dv, lim)

fun save_one(doc: !Doc, path: !Buf, go: int): void =
  if ieq(go, 1) then let
    val p = cstr(path)
    val _s = doc_save_physical(doc, p)
  in
    ()
  end else let
    val _n = touch_doc(doc)
  in
    ()
  end

fun resolve_save_path(path: Buf, title: !Buf, vault: !Buf, idx: int): Buf =
  if ieq(idx, 0) andalso ieq(buf_len(path), 0) andalso igt(buf_len(vault), 0) then let
    var nb = buf_make(iadd(buf_len(vault), iadd(buf_len(title), 8)))
    val () = child_path(vault, title, nb)
    val need_md = if ends(nb, ".md") = 0 then 1 else 0
    val () = bstr_if(nb, need_md, ".md")
    val () = buf_free(path)
  in
    nb
  end else path

fun tabs_save_impl(ts: Tabs, idx: int, vault: !Buf): Tabs =
  case+ ts of
  | ~TNil() => TNil()
  | ~TCons(doc, path, title, sc, rest) => let
      val path_to_save = resolve_save_path(path, title, vault, idx)
      val () = save_one(doc, path_to_save, iif(ieq(idx, 0) andalso igt(buf_len(path_to_save), 0), 1, 0))
      val _v = buf_len(vault)
    in
      TCons(doc, path_to_save, title, sc, save_rest(ieq(idx, 0), rest, idx, vault))
    end
and save_rest(stop: bool, rest: Tabs, idx: int, vault: !Buf): Tabs =
  if stop then rest else tabs_save_impl(rest, isub(idx, 1), vault)

implement tabs_save(ts, idx, vault) = tabs_save_impl(ts, idx, vault)

fun sync_vfs_one(doc: !Doc, path: !Buf, go: int): void =
  if ieq(go, 1) andalso igt(buf_len(path), 0) then let
    val p = cstr(path)
    val _s = doc_save_physical(doc, p)
  in
    ()
  end else let
    val _n = touch_doc(doc)
  in
    ()
  end

fun tabs_sync_vfs_impl(ts: !Tabs, idx: int): void =
  case+ ts of
  | @TNil() => fold@(ts)
  | @TCons(doc, path, title, sc, rest) => let
      val () = sync_vfs_one(doc, path, iif(ieq(idx, 0), 1, 0))
      val () = if ine(idx, 0) then tabs_sync_vfs_impl(rest, isub(idx, 1)) else ()
      val _s = sc
    in
      fold@(ts)
    end

implement tabs_sync_vfs(ts, idx) = tabs_sync_vfs_impl(ts, idx)

fun tabs_save_all_physical_impl(ts: !Tabs): void =
  case+ ts of
  | @TNil() => fold@(ts)
  | @TCons(doc, path, title, sc, rest) => let
      val () = if igt(buf_len(path), 0) then let
        val p = cstr(path)
        val _s = doc_save_physical(doc, p)
      in
      end else ()
      val () = tabs_save_all_physical_impl(rest)
      val _s = sc
    in
      fold@(ts)
    end

implement tabs_save_all_physical(ts) = tabs_save_all_physical_impl(ts)

fun resolve_one_path(path: Buf, title: !Buf, vault: !Buf): Buf =
  if ieq(buf_len(path), 0) andalso igt(buf_len(vault), 0) then let
    var nb = buf_make(iadd(buf_len(vault), iadd(buf_len(title), 8)))
    val () = child_path(vault, title, nb)
    val need_md = if ends(nb, ".md") = 0 then 1 else 0
    val () = bstr_if(nb, need_md, ".md")
    val () = buf_free(path)
  in
    nb
  end else path

fun tabs_ensure_paths_impl(ts: Tabs, vault: !Buf): Tabs =
  case+ ts of
  | ~TNil() => TNil()
  | ~TCons(doc, path, title, sc, rest) => let
      val p2 = resolve_one_path(path, title, vault)
      val () = if igt(buf_len(p2), 0) then let
          val _s = doc_save_physical(doc, cstr(p2))
        in () end else ()
    in
      TCons(doc, p2, title, sc, tabs_ensure_paths_impl(rest, vault))
    end

implement tabs_ensure_paths(ts, vault) = tabs_ensure_paths_impl(ts, vault)

fun tabs_text_impl(ts: !Tabs, idx: int, dst: &Buf >> _): void =
  case+ ts of
  | @TNil() => fold@(ts)
  | @TCons(doc, path, title, sc, rest) => let
      val () = text_rest(iif(ieq(idx, 0), 1, 0), doc, rest, idx, dst)
      val _n = buf_len(path)
      val _m = buf_len(title)
      val _s = sc
    in
      fold@(ts)
    end
and text_rest(stop: int, doc: !Doc, rest: !Tabs, idx: int, dst: &Buf >> _): void =
  if ieq(stop, 1) then doc_text(doc, dst) else tabs_text_impl(rest, isub(idx, 1), dst)

implement tabs_text(ts, idx, dst) = tabs_text_impl(ts, idx, dst)

fun slice_here(doc: !Doc, a: int, b: int, dst: &Buf >> _): int = let
  val k = doc_slice(doc, a, b, buf_ptr(dst), buf_cap(dst))
  val () = buf_set_len(dst, k)
in
  k
end

fun tabs_slice_impl(ts: !Tabs, idx: int, a: int, b: int, dst: &Buf >> _): int =
  case+ ts of
  | @TNil() => (fold@(ts); 0)
  | @TCons(doc, path, title, sc, rest) => let
      val n = slice_rest(iif(ieq(idx, 0), 1, 0), doc, rest, idx, a, b, dst)
      val _u = buf_len(path)
      val _v = buf_len(title)
      val _s = sc
    in
      fold@(ts); n
    end
and slice_rest(stop: int, doc: !Doc, rest: !Tabs, idx: int, a: int, b: int, dst: &Buf >> _): int =
  if ieq(stop, 1) then slice_here(doc, a, b, dst) else tabs_slice_impl(rest, isub(idx, 1), a, b, dst)

implement tabs_slice(ts, idx, a, b, dst) = tabs_slice_impl(ts, idx, a, b, dst)

fun copy_here(doc: !Doc, dst: &Buf >> _): void = let
  val a = doc_anchor(doc)
  val c = doc_caret(doc)
  val lo = imin(a, c)
  val hi = imax(a, c)
  val () = buf_ensure(dst, iadd(isub(hi, lo), 2))
  val cap = buf_cap(dst)
  val n = doc_slice(doc, lo, hi, buf_ptr(dst), cap)
in
  buf_set_len(dst, n)
end

fun tabs_copy_impl(ts: !Tabs, idx: int, dst: &Buf >> _): void =
  case+ ts of
  | @TNil() => fold@(ts)
  | @TCons(doc, path, title, sc, rest) => let
      val () = copy_arm(iif(ieq(idx, 0), 1, 0), doc, rest, idx, dst)
      val _n = buf_len(path)
      val _m = buf_len(title)
      val _s = sc
    in
      fold@(ts)
    end
and copy_arm(stop: int, doc: !Doc, rest: !Tabs, idx: int, dst: &Buf >> _): void =
  if ieq(stop, 1) then copy_here(doc, dst) else tabs_copy_impl(rest, isub(idx, 1), dst)

implement tabs_copy(ts, idx, dst) = tabs_copy_impl(ts, idx, dst)

implement tabs_open(ts, path) = let
  val doc = doc_open()
  val _n = doc_load(doc, cstr(path))
  var title = buf_make(8)
  val () = base_name(path, title)
in
  tabs_add(ts, doc, path, title)
end

implement tabs_detach(ts, i) =
  case+ ts of
  | ~TNil() => PAIR(TNil(), TNil())
  | ~TCons(doc, path, title, sc, rest) =>
      if ieq(i, 0) then PAIR(TCons(doc, path, title, sc, TNil()), rest)
      else let
        val+ ~PAIR(one, tail) = tabs_detach(rest, isub(i, 1))
      in
        PAIR(one, TCons(doc, path, title, sc, tail))
      end

implement tabs_link(one, ts) =
  case+ one of
  | ~TNil() => ts
  | ~TCons(doc, path, title, sc, rest) => let
      val () = tabs_free(rest)
    in
      TCons(doc, path, title, sc, ts)
    end

implement tabs_insert(ts, i, one) =
  if ieq(i, 0) then tabs_link(one, ts)
  else case+ ts of
    | ~TNil() => one
    | ~TCons(doc, path, title, sc, rest) => TCons(doc, path, title, sc, tabs_insert(rest, isub(i, 1), one))

fun tabs_toggle_impl(ts: Tabs, idx: int, ni: int): Tabs =
  case+ ts of
  | ~TNil() => TNil()
  | ~TCons(doc, path, title, sc, rest) => let
      val () = if ieq(idx, 0) andalso ige(ni, 0) then doc_toggle(doc, ni) else ()
    in
      TCons(doc, path, title, sc, toggle_rest(ieq(idx, 0), rest, idx, ni))
    end
and toggle_rest(stop: bool, rest: Tabs, idx: int, ni: int): Tabs =
  if stop then rest else tabs_toggle_impl(rest, isub(idx, 1), ni)

implement tabs_toggle(ts, idx, ni) = tabs_toggle_impl(ts, idx, ni)

fun tabs_toggle_task_impl(ts: Tabs, idx: int, ni: int): Tabs =
  case+ ts of
  | ~TNil() => TNil()
  | ~TCons(doc, path, title, sc, rest) => let
      val () = if ieq(idx, 0) andalso ige(ni, 0) then doc_toggle_task(doc, ni) else ()
    in
      TCons(doc, path, title, sc, toggle_task_rest(ieq(idx, 0), rest, idx, ni))
    end
and toggle_task_rest(stop: bool, rest: Tabs, idx: int, ni: int): Tabs =
  if stop then rest else tabs_toggle_task_impl(rest, isub(idx, 1), ni)

implement tabs_toggle_task(ts, idx, ni) = tabs_toggle_task_impl(ts, idx, ni)
