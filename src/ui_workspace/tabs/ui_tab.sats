staload "mem.sats"
staload "data_ast/document/doc.sats"
staload "os/file_stamp.sats"
staload "ui_workspace/commands/ui_cmd.sats"

datavtype Tabs =
  | TNil of ()
  | TCons of (Doc, Buf, Buf, int, Tabs)

datavtype Pair = PAIR of (Tabs, Tabs)

(* Documents of closed tabs, kept whole (text, AST, rows, layout), newest first.
   A tab is saved before it closes, so the file stamp taken right after closing
   identifies the kept content exactly; a reopen of the unchanged file reuses
   the document, any later change on disk drops it. At most
   CLOSED_DOCS_MAX_ENTRIES documents and CLOSED_DOCS_BUDGET_BYTES (estimated). *)
datavtype ClosedDocs =
  | ClosedNone of ()
  | ClosedKept of (Buf, FileStamp, int, Doc, ClosedDocs)
fun closed_docs_free(kept: ClosedDocs): void
fun closed_docs_count(kept: !ClosedDocs): int
(* Same as tabs_drop / tabs_open, but closing keeps the document and opening
   reuses a kept one. ANTHRACITE_TAB_CACHE=0 keeps nothing. *)
fun tabs_drop_kept(ts: Tabs, i: int, kept: &ClosedDocs >> _): Tabs
fun tabs_open_kept(ts: Tabs, path: Buf, kept: &ClosedDocs >> _): Tabs

fun tabs_free(ts: Tabs): void
fun tabs_len(ts: !Tabs): int
fun tabs_drop(ts: Tabs, i: int): Tabs
fun tabs_add(ts: Tabs, doc: Doc, path: Buf, title: Buf): Tabs
fun tabs_replace(ts: Tabs, idx: int, doc: Doc, path: Buf, title: Buf): Tabs
fun tabs_append(ts: Tabs, doc: Doc, path: Buf, title: Buf, sc: int): Tabs
fun tabs_cmd(ts: Tabs, idx: int, cmd: Cmd): Tabs
fun tabs_ins(ts: Tabs, idx: int, p: ptr, n: int): Tabs
fun tabs_ins_buf(ts: Tabs, idx: int, b: !Buf, n: int): Tabs
fun tabs_scroll(ts: Tabs, idx: int, dv: int, lim: int): Tabs
fun tabs_get_scroll(ts: !Tabs, idx: int): int
fun tabs_set_scroll(ts: Tabs, idx: int, sc: int): Tabs
fun tabs_set_caret(ts: Tabs, idx: int, c: int): Tabs
fun tabs_get_path(ts: !Tabs, idx: int, dst: &Buf >> _): void
fun tabs_get_title(ts: !Tabs, idx: int, dst: &Buf >> _): void
fun tabs_rename_prefix(ts: Tabs, old_p: !Buf, new_p: !Buf): Tabs
fun tabs_copy(ts: !Tabs, idx: int, dst: &Buf >> _): void
fun tabs_open(ts: Tabs, path: Buf): Tabs
fun tabs_open_at(ts: Tabs, idx: int, path: Buf): Tabs
fun tabs_detach(ts: Tabs, i: int): Pair
fun tabs_link(one: Tabs, ts: Tabs): Tabs
fun tabs_insert(ts: Tabs, i: int, one: Tabs): Tabs
fun tabs_move(ts: Tabs, from_i: int, to_i: int): Tabs
fun tabs_clone_tab(ts: Tabs, idx: int): Tabs
fun tabs_toggle(ts: Tabs, idx: int, ni: int): Tabs
fun tabs_toggle_deep(ts: Tabs, idx: int, ni: int): Tabs
fun tabs_toggle_task(ts: Tabs, idx: int, ni: int): Tabs
fun tabs_sync_vfs(ts: !Tabs, idx: int): void
fun tabs_save_all_physical(ts: !Tabs): void
fun tabs_ensure_paths(ts: Tabs, vault: !Buf): Tabs
fun tabs_flush_paths(ts: Tabs, vault: !Buf): Tabs
fun touch_doc(d: !Doc): void
fun tabs_jump(ts: Tabs, idx: int, line: int, col: int): Tabs
fun tabs_jump_span(ts: Tabs, idx: int, line: int, col: int, mlen: int): Tabs
fun tabs_find_doc(ts: !Tabs, idx: int, q: !Buf, from: int, dir: int): int
fun tabs_select_range(ts: Tabs, idx: int, st: int, en: int): Tabs
fun tabs_select_word_at(ts: Tabs, idx: int, pos: int): Tabs
fun tabs_find_path(ts: !Tabs, p: !Buf): int
fun tabs_caret(ts: !Tabs, idx: int): int
fun tabs_anchor(ts: !Tabs, idx: int): int
fun tabs_copy_doc_text(ts: !Tabs, p: !Buf, dst: &Buf >> _): int
fun tabs_sync_cursor_focus(ts: !Tabs, focused: bool, active_idx: int): void
fun tabs_wrap(ts: Tabs, idx: int, pre: string, plen: int, suf: string, suflen: int): Tabs
fun tabs_set_line_prefix(ts: Tabs, idx: int, pre: string, plen: int): Tabs
fun tabs_discard_matching(ts: Tabs, target: !Buf, is_dir: bool): Tabs
