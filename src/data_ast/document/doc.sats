staload "mem.sats"
staload "flag.sats"

absviewtype Doc = ptr

macdef AST_NODE_WORDS = 16

datatype NodeKind =
  | KNone
  | KPara
  | KH1 | KH2 | KH3 | KH4 | KH5 | KH6
  | KUl | KOl | KLi
  | KQuote | KCode | KHr | KTable
  | KText | KWiki | KEmbed | KTag | KTask
  | KFn | KFndef | KHigh | KMath | KMathb | KFm
  | KImage | KTd | KBold | KItalic | KStrike | KLink
  | KMark | KRaw | KInfo | KEscape | KCodeSpan | KUrl
  | KHtmlBlock | KHtmlInline | KBreak | KComment | KBlockId
  | KCallout | KCalloutHead | KTableRow | KTableCell | KTableDelim
  | KLinkDest | KLinkTitle | KWikiTarget | KWikiHeading | KWikiBlock | KWikiAlias
  | KFnInline | KMathBlock | KDirective

fun kind_of(n: int): NodeKind
fun kind_code(k: NodeKind): int
fun heading_kind(hashes: int): NodeKind
fun is_kind(k: NodeKind, expect: NodeKind): bool
fun is_heading(k: NodeKind): bool
fun is_inline(k: NodeKind): bool
fun kind_is_leaf(k: NodeKind): bool
fun kind_is_block(k: NodeKind): bool
fun kind_is_container(k: NodeKind): bool
fun heading_stops(k: NodeKind, limit: NodeKind): bool
fun ast_style(d: !Doc, i: int): int

macdef NF_KIND = 0
macdef NF_START = 1
macdef NF_END = 2
macdef NF_DEPTH = 3
macdef NF_COLLAPSED = 4
macdef NF_HEIGHT = 5
macdef NF_PARENT = 6
macdef NF_NEXT_SIB = 7
macdef NF_FIRST_CHILD = 8
macdef NF_HIDDEN = 9
macdef NF_AUX = 10
macdef NF_CSTART = 11
macdef NF_CEND = 12
macdef NF_Y = 13
macdef NF_SUBEND = 14
macdef NF_FLAGS = 15

datatype TaskMark = TaskTodo | TaskDone | TaskProgress | TaskOther

fun task_mark_of(c: int): TaskMark
fun task_next_mark(m: TaskMark): TaskMark
fun task_mark_byte(m: TaskMark): int
fun task_aux_code(m: TaskMark): int

fun doc_node_kind(d: !Doc, i: int): NodeKind
fun doc_node_start(d: !Doc, i: int): int
fun doc_node_end(d: !Doc, i: int): int
fun doc_node_depth(d: !Doc, i: int): int
fun doc_node_collapsed(d: !Doc, i: int): Toggle
fun doc_node_height(d: !Doc, i: int): int
fun doc_node_parent(d: !Doc, i: int): int
fun doc_node_first_child(d: !Doc, i: int): int
fun doc_node_next_sib(d: !Doc, i: int): int
fun doc_node_hidden(d: !Doc, i: int): Toggle
fun doc_node_aux(d: !Doc, i: int): int
fun doc_node_cstart(d: !Doc, i: int): int
fun doc_node_cend(d: !Doc, i: int): int
fun doc_node_y(d: !Doc, i: int): int
fun doc_node_subend(d: !Doc, i: int): int
fun doc_node_flags(d: !Doc, i: int): int

fun doc_node_add(d: !Doc, kind: NodeKind, st: int, en: int, parent: int, prev_sib: int, aux: int, flags: int): int
fun doc_node_close(d: !Doc, i: int, en: int, cs: int, ce: int): void
fun doc_find_child(d: !Doc, i: int, kind: NodeKind): int
fun doc_ver(d: !Doc): int
fun doc_bump_ver(d: !Doc): void
fun doc_clear_nodes(d: !Doc): void

fun doc_open(): Doc
fun doc_is_md(d: !Doc): Toggle
fun doc_set_md(d: !Doc, is_md: Toggle): void
fun doc_embed_level(d: !Doc): int
fun doc_set_embed_level(d: !Doc, level: int): void
fun doc_free(d: Doc): void
fun doc_len(d: !Doc): int
fun doc_touch(d: !Doc): void
fun doc_caret(d: !Doc): int
fun doc_anchor(d: !Doc): int
fun doc_set_caret_move(d: !Doc, i: int): void
fun doc_set_caret_extend(d: !Doc, i: int): void
fun doc_insert(d: !Doc, p: ptr, n: int): void
fun doc_insert_buf(d: !Doc, src: !Buf, n: int): void
fun doc_backspace(d: !Doc): void
fun doc_delete(d: !Doc): void
fun doc_delete_range(d: !Doc, start: int, finish: int): void
fun doc_undo(d: !Doc): void
fun doc_redo(d: !Doc): void
fun doc_wrap(d: !Doc, pre: string, plen: int, suf: string, suflen: int): void
fun doc_left_move(d: !Doc): void
fun doc_left_select(d: !Doc): void
fun doc_right_move(d: !Doc): void
fun doc_right_select(d: !Doc): void
fun doc_up_move(d: !Doc): void
fun doc_up_select(d: !Doc): void
fun doc_down_move(d: !Doc): void
fun doc_down_select(d: !Doc): void
fun doc_home_move(d: !Doc): void
fun doc_home_select(d: !Doc): void
fun doc_end_move(d: !Doc): void
fun doc_end_select(d: !Doc): void
fun doc_word_left_move(d: !Doc): void
fun doc_word_left_select(d: !Doc): void
fun doc_word_right_move(d: !Doc): void
fun doc_word_right_select(d: !Doc): void
fun doc_del_word_left(d: !Doc): void
fun doc_del_word_right(d: !Doc): void
fun doc_doc_start_move(d: !Doc): void
fun doc_doc_start_select(d: !Doc): void
fun doc_doc_end_move(d: !Doc): void
fun doc_doc_end_select(d: !Doc): void
fun doc_page_up_move(d: !Doc, nlines: int): void
fun doc_page_up_select(d: !Doc, nlines: int): void
fun doc_page_down_move(d: !Doc, nlines: int): void
fun doc_page_down_select(d: !Doc, nlines: int): void
fun doc_byte(d: !Doc, i: int): int
fun doc_slice(d: !Doc, a: int, b: int, dst: ptr, cap: int): int
fun doc_slice_buf(d: !Doc, a: int, b: int, dst: !Buf, cap: int): int
fun doc_text(d: !Doc, dst: &Buf >> _): void
fun doc_load(d: !Doc, path: string): bool
fun doc_load_checked(d: !Doc, path: string): bool
fun doc_save(d: !Doc, path: string): int
fun doc_save_vfs(d: !Doc, path: string): int
fun doc_save_physical(d: !Doc, path: string): int
fun doc_nlines(d: !Doc): int
fun doc_line_start(d: !Doc, i: int): int
fun doc_line_y(d: !Doc, i: int): int
fun doc_line_step(d: !Doc, i: int): int
fun doc_line_of(d: !Doc, off: int): int
fun doc_set_flash(d: !Doc, line: int, until: lint): void
fun doc_get_flash(d: !Doc, now: lint): int
fun doc_nnodes(d: !Doc): int
fun doc_get(d: !Doc, i: int, f: int): int
fun doc_set(d: !Doc, i: int, f: int, v: int): void
fun doc_push_node(d: !Doc, kind: NodeKind, st: int, en: int, depth: int, aux: int): void
fun doc_is_foldable(d: !Doc, i: int): bool
fun doc_line_node_foldable(d: !Doc, line: int): int
fun doc_compute_foldability(d: !Doc): void
fun doc_toggle(d: !Doc, i: int): void
fun doc_toggle_deep(d: !Doc, i: int): void
fun doc_toggle_task(d: !Doc, i: int): void
fun doc_node_fold_end(d: !Doc, i: int): int
fun doc_node_fold_body_start(d: !Doc, i: int): int
fun fold_has(d: !Doc, off: int): bool
fun fold_add(d: !Doc, off: int): void
fun fold_del(d: !Doc, off: int): void
fun fold_count(d: !Doc): int
fun doc_is_line_hidden(d: !Doc, line: int): int
fun doc_line_region(d: !Doc, line: int): int
fun doc_region_count(d: !Doc): int
fun doc_region_owner(d: !Doc, idx: int): int
fun doc_region_end(d: !Doc, idx: int): int
fun doc_region_offset(d: !Doc, idx: int): int
fun folds_apply_edit(d: !Doc, at: int, del_bytes: int, ins_bytes: int): void
fun doc_span(d: !Doc): int
fun doc_set_span(d: !Doc, v: int): void
fun lines_apply_edit(d: !Doc, at: int, oldlen: int, newlen: int): void
fun doc_layout(d: !Doc, lh: int): int
fun doc_layout_mode(d: !Doc, lh: int, is_read: int, colw: int): int
fun doc_wrap_cols(colw: int): int
fun doc_get_wrap(d: !Doc): int
fun column_w(avail: int): int
fun column_x(pane: int, avail: int): int
fun doc_codepoints(d: !Doc, st: int, en: int): int
fun doc_advance_cps(d: !Doc, st: int, en: int, k: int): int
fun doc_selftest(): int
fun doc_fold_dump(path: string): void
