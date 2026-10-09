#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "os/diag.sats"
staload "data_ast/doc.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/ui_tab.sats"
staload "ui_workspace/ui_cmd.sats"

#include "common.hats"

implement touch_doc(d) = doc_touch(d)

extern fun tabs_free_exh(ts: Tabs): void = "mac#anth_die_void"

fun tabs_free_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs): void =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => ()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = doc_free(doc)
        val () = buf_free(path)
        val () = buf_free(title)
        val () = seen_int(sc)
      in
        tabs_free_m(recfuel - 1, rest)
      end
  ) else tabs_free_exh(ts)

implement tabs_free(ts) = tabs_free_m(airlock_nat(MAX_REC_FUEL), ts)

extern fun tabs_len_exh(ts: !Tabs): int = "mac#anth_die_int"

fun tabs_len_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: !Tabs): int =
  if recfuel > 0 then (
    case+ ts of
    | @TNil() => (fold@(ts); 0)
    | @TCons(doc, _p, _t, _s, rest) => let
        val n = iadd(tabs_len_m(recfuel - 1, rest), 1)
        val () = doc_touch(doc)
      in
        fold@(ts); n
      end

  (* Yolu bos olan belge kaydedilecek bir sey olmadigi icin basarili sayilir. *)
  ) else tabs_len_exh(ts)

implement tabs_len(ts) = tabs_len_m(airlock_nat(MAX_REC_FUEL), ts)

fun save_ok(doc: !Doc, path: !Buf): int =
  if igt(buf_len(path), 0) then let
    val ok = doc_save_physical(doc, cstr(path))
  in
    if ieq(ok, 1) then 1
    else let
      val () = report_failure("doc_save", cstr(path))
    in
      0
    end
  end
  else 1

(* Kayit basarisiz olursa sekme korunur: veri kaybi olmaz. *)
fun drop_head(doc: Doc, path: Buf, title: Buf, sc: int, rest: Tabs): Tabs =
  if ieq(save_ok(doc, path), 1) then let
    val () = doc_free(doc)
    val () = buf_free(path)
    val () = buf_free(title)
    val () = seen_int(sc)
  in
    rest
  end
  else TCons(doc, path, title, sc, rest)

extern fun tabs_drop_exh(ts: Tabs, i: int): Tabs = "mac#anth_die_box"

fun tabs_drop_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, i: int): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) =>
        if ieq(i, 0) then drop_head(doc, path, title, sc, rest)
        else TCons(doc, path, title, sc, tabs_drop_m(recfuel - 1, rest, isub(i, 1)))
  ) else tabs_drop_exh(ts, i)

implement tabs_drop(ts, i) = tabs_drop_m(airlock_nat(MAX_REC_FUEL), ts, i)

extern fun tabs_append_impl_exh(ts: Tabs, doc: Doc, path: Buf, title: Buf, sc: int): Tabs = "mac#anth_die_box"

fun tabs_append_impl_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, doc: Doc, path: Buf, title: Buf, sc: int): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => TCons(doc, path, title, sc, TNil())
    | ~TCons(d, p, t, s, rest) => TCons(d, p, t, s, tabs_append_impl_m(recfuel - 1, rest, doc, path, title, sc))
  ) else tabs_append_impl_exh(ts, doc, path, title, sc)

fun tabs_append_impl(ts: Tabs, doc: Doc, path: Buf, title: Buf, sc: int): Tabs = tabs_append_impl_m(airlock_nat(MAX_REC_FUEL), ts, doc, path, title, sc)

implement tabs_append(ts, doc, path, title, sc) =
  tabs_append_impl(ts, doc, path, title, sc)

implement tabs_add(ts, doc, path, title) =
  tabs_append_impl(ts, doc, path, title, 0)

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

fun run_caret_motion_cmd(d: !Doc, cmd: Cmd): void =
  if is_cmd(cmd, CMD_CARET_LEFT) then doc_left_move(d)
  else if is_cmd(cmd, CMD_CARET_RIGHT) then doc_right_move(d)
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
  else if is_cmd(cmd, CMD_SELECT_LEFT) then doc_left_select(d)
  else if is_cmd(cmd, CMD_SELECT_RIGHT) then doc_right_select(d)
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

fun run_cmd(d: !Doc, cmd: Cmd): void = let
  val () = run_motion_cmd(d, cmd)
in
  run_edit_cmd(d, cmd)
end

extern fun tabs_cmd_impl_exh(ts: Tabs, idx: int, cmd: Cmd): Tabs = "mac#anth_die_box"

fun tabs_cmd_impl_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int, cmd: Cmd): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = if ieq(idx, 0) then run_cmd(doc, cmd) else ()
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc, rest) else TCons(doc, path, title, sc, tabs_cmd_impl_m(recfuel - 1, rest, isub(idx, 1), cmd))
      end
  ) else tabs_cmd_impl_exh(ts, idx, cmd)

fun tabs_cmd_impl(ts: Tabs, idx: int, cmd: Cmd): Tabs = tabs_cmd_impl_m(airlock_nat(MAX_REC_FUEL), ts, idx, cmd)

implement tabs_cmd(ts, idx, cmd) = tabs_cmd_impl(ts, idx, cmd)

extern fun tabs_ins_impl_exh(ts: Tabs, idx: int, p: ptr, n: int): Tabs = "mac#anth_die_box"

fun tabs_ins_impl_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int, p: ptr, n: int): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = if ieq(idx, 0) andalso igt(n, 0) then doc_insert(doc, p, n) else ()
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc, rest) else TCons(doc, path, title, sc, tabs_ins_impl_m(recfuel - 1, rest, isub(idx, 1), p, n))
      end
  ) else tabs_ins_impl_exh(ts, idx, p, n)

fun tabs_ins_impl(ts: Tabs, idx: int, p: ptr, n: int): Tabs = tabs_ins_impl_m(airlock_nat(MAX_REC_FUEL), ts, idx, p, n)

implement tabs_ins(ts, idx, p, n) = tabs_ins_impl(ts, idx, p, n)

implement tabs_ins_buf(ts, idx, b, n) = tabs_ins(ts, idx, buf_ptr(b), n)

extern fun tabs_scroll_impl_exh(ts: Tabs, idx: int, dv: int, lim: int): Tabs = "mac#anth_die_box"

fun tabs_scroll_impl_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int, dv: int, lim: int): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val sc2 = if ieq(idx, 0) then imax(0, imin(lim, iadd(sc, dv))) else sc
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc2, rest) else TCons(doc, path, title, sc2, tabs_scroll_impl_m(recfuel - 1, rest, isub(idx, 1), dv, lim))
      end
  ) else tabs_scroll_impl_exh(ts, idx, dv, lim)

fun tabs_scroll_impl(ts: Tabs, idx: int, dv: int, lim: int): Tabs = tabs_scroll_impl_m(airlock_nat(MAX_REC_FUEL), ts, idx, dv, lim)

implement tabs_scroll(ts, idx, dv, lim) = tabs_scroll_impl(ts, idx, dv, lim)


fun resolve_save_path(path: Buf, title: !Buf, vault: !Buf, idx: int): Buf =
  if ieq(idx, 0) andalso ieq(buf_len(path), 0) andalso igt(buf_len(vault), 0) then let
    var nb = buf_make(iadd(buf_len(vault), iadd(buf_len(title), 8)))
    val () = child_path(vault, title, nb)
    val need_md = not(ends(nb, ".md"))
    val () = bstr_if(nb, toggle_of(need_md), ".md")
    val () = buf_free(path)
  in
    nb
  end else path

fun resolve_one_path(path: Buf, title: !Buf, vault: !Buf): Buf =
  resolve_save_path(path, title, vault, 0)


fun sync_vfs_one(doc: !Doc, path: !Buf, go: Toggle): void =
  if is_on(go) andalso igt(buf_len(path), 0) then let
    val () = seen_int(save_ok(doc, path))
  in
    ()
  end else let
    val () = touch_doc(doc)
  in
    ()
  end

extern fun tabs_sync_vfs_impl_exh(ts: !Tabs, idx: int): void = "mac#anth_die_void"

fun tabs_sync_vfs_impl_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: !Tabs, idx: int): void =
  if recfuel > 0 then (
    case+ ts of
    | @TNil() => fold@(ts)
    | @TCons(doc, path, title, sc, rest) => let
        val () = sync_vfs_one(doc, path, toggle_of(ieq(idx, 0)))
        val () = if ine(idx, 0) then tabs_sync_vfs_impl_m(recfuel - 1, rest, isub(idx, 1)) else ()
        val () = seen_int(sc)
      in
        fold@(ts)
      end
  ) else tabs_sync_vfs_impl_exh(ts, idx)

fun tabs_sync_vfs_impl(ts: !Tabs, idx: int): void = tabs_sync_vfs_impl_m(airlock_nat(MAX_REC_FUEL), ts, idx)

implement tabs_sync_vfs(ts, idx) = tabs_sync_vfs_impl(ts, idx)

extern fun tabs_save_all_physical_impl_exh(ts: !Tabs): void = "mac#anth_die_void"

fun tabs_save_all_physical_impl_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: !Tabs): void =
  if recfuel > 0 then (
    case+ ts of
    | @TNil() => fold@(ts)
    | @TCons(doc, path, title, sc, rest) => let
        val () = seen_int(save_ok(doc, path))
        val () = tabs_save_all_physical_impl_m(recfuel - 1, rest)
        val () = seen_int(sc)
      in
        fold@(ts)
      end
  ) else tabs_save_all_physical_impl_exh(ts)

fun tabs_save_all_physical_impl(ts: !Tabs): void = tabs_save_all_physical_impl_m(airlock_nat(MAX_REC_FUEL), ts)

implement tabs_save_all_physical(ts) = tabs_save_all_physical_impl(ts)

extern fun tabs_ensure_paths_impl_exh(ts: Tabs, vault: !Buf): Tabs = "mac#anth_die_box"

fun tabs_ensure_paths_impl_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, vault: !Buf): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val p2 = resolve_one_path(path, title, vault)
        val () = seen_int(save_ok(doc, p2))
      in
        TCons(doc, p2, title, sc, tabs_ensure_paths_impl_m(recfuel - 1, rest, vault))
      end
  ) else tabs_ensure_paths_impl_exh(ts, vault)

fun tabs_ensure_paths_impl(ts: Tabs, vault: !Buf): Tabs = tabs_ensure_paths_impl_m(airlock_nat(MAX_REC_FUEL), ts, vault)

implement tabs_ensure_paths(ts, vault) = tabs_ensure_paths_impl(ts, vault)


fun copy_here(doc: !Doc, dst: &Buf >> _): void = let
  val a = doc_anchor(doc)
  val c = doc_caret(doc)
  val lo = imin(a, c)
  val hi = imax(a, c)
  val () = buf_ensure(dst, iadd(isub(hi, lo), 2))
  val cap = buf_cap(dst)
  val n = doc_slice_buf(doc, lo, hi, dst, cap)
in
  buf_set_len(dst, n)
end

fun tabs_copy_impl {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: !Tabs, idx: int, dst: &Buf >> _): void =
  if recfuel > 0 then (
    case+ ts of
    | @TNil() => fold@(ts)
    | @TCons(doc, path, title, sc, rest) => let
        val () = copy_arm(recfuel - 1, toggle_of(ieq(idx, 0)), doc, rest, idx, dst)
        val () = seen_buf(path)
        val () = seen_buf(title)
        val () = seen_int(sc)
      in
        fold@(ts)
      end
  ) else touchb(dst)
and copy_arm {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), stop: Toggle, doc: !Doc, rest: !Tabs, idx: int, dst: &Buf >> _): void =
  if recfuel > 0 then (
    if is_on(stop) then copy_here(doc, dst) else tabs_copy_impl(recfuel - 1, rest, isub(idx, 1), dst)
  ) else touchb(dst)

implement tabs_copy(ts, idx, dst) = tabs_copy_impl(airlock_nat(MAX_REC_FUEL), ts, idx, dst)

(* Var olan ama okunamayan dosya acilmaz: bos belge kaydedilip dosya ezilmesin. *)
fun open_loaded(ts: Tabs, doc: Doc, path: Buf): Tabs = let
  var title = buf_make(8)
  val () = base_name(path, title)
in
  tabs_add(ts, doc, path, title)
end

implement tabs_open(ts, path) = let
  val doc = doc_open()
  val ok = doc_load_checked(doc, cstr(path))
in
  if ieq(ok, 1) then open_loaded(ts, doc, path)
  else let
    val () = doc_free(doc)
    val () = buf_free(path)
  in
    ts
  end
end

extern fun tabs_detach_exh(ts: Tabs, i: int): Pair = "mac#anth_die_box"

fun tabs_detach_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, i: int): Pair =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => PAIR(TNil(), TNil())
    | ~TCons(doc, path, title, sc, rest) =>
        if ieq(i, 0) then PAIR(TCons(doc, path, title, sc, TNil()), rest)
        else let
          val+ ~PAIR(one, tail) = tabs_detach_m(recfuel - 1, rest, isub(i, 1))
        in
          PAIR(one, TCons(doc, path, title, sc, tail))
        end
  ) else tabs_detach_exh(ts, i)

implement tabs_detach(ts, i) = tabs_detach_m(airlock_nat(MAX_REC_FUEL), ts, i)

implement tabs_link(one, ts) =
  case+ one of
  | ~TNil() => ts
  | ~TCons(doc, path, title, sc, rest) => let
      val () = tabs_free(rest)
    in
      TCons(doc, path, title, sc, ts)
    end

extern fun tabs_insert_exh(ts: Tabs, i: int, one: Tabs): Tabs = "mac#anth_die_box"

fun tabs_insert_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, i: int, one: Tabs): Tabs =
  if recfuel > 0 then (
    if ieq(i, 0) then tabs_link(one, ts)
    else case+ ts of
      | ~TNil() => one
      | ~TCons(doc, path, title, sc, rest) => TCons(doc, path, title, sc, tabs_insert_m(recfuel - 1, rest, isub(i, 1), one))
  ) else tabs_insert_exh(ts, i, one)

implement tabs_insert(ts, i, one) = tabs_insert_m(airlock_nat(MAX_REC_FUEL), ts, i, one)

extern fun tabs_toggle_impl_exh(ts: Tabs, idx: int, ni: int): Tabs = "mac#anth_die_box"

fun tabs_toggle_impl_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int, ni: int): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = if ieq(idx, 0) andalso ige(ni, 0) then doc_toggle(doc, ni) else ()
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc, rest) else TCons(doc, path, title, sc, tabs_toggle_impl_m(recfuel - 1, rest, isub(idx, 1), ni))
      end
  ) else tabs_toggle_impl_exh(ts, idx, ni)

fun tabs_toggle_impl(ts: Tabs, idx: int, ni: int): Tabs = tabs_toggle_impl_m(airlock_nat(MAX_REC_FUEL), ts, idx, ni)

implement tabs_toggle(ts, idx, ni) = tabs_toggle_impl(ts, idx, ni)

extern fun tabs_toggle_task_impl_exh(ts: Tabs, idx: int, ni: int): Tabs = "mac#anth_die_box"

fun tabs_toggle_task_impl_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int, ni: int): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = if ieq(idx, 0) andalso ige(ni, 0) then doc_toggle_task(doc, ni) else ()
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc, rest) else TCons(doc, path, title, sc, tabs_toggle_task_impl_m(recfuel - 1, rest, isub(idx, 1), ni))
      end
  ) else tabs_toggle_task_impl_exh(ts, idx, ni)

fun tabs_toggle_task_impl(ts: Tabs, idx: int, ni: int): Tabs = tabs_toggle_task_impl_m(airlock_nat(MAX_REC_FUEL), ts, idx, ni)

implement tabs_toggle_task(ts, idx, ni) = tabs_toggle_task_impl(ts, idx, ni)
