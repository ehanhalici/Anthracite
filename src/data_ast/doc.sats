staload "mem.sats"
staload "flag.sats"

absviewtype Doc = ptr

macdef NS = 16
macdef NK_PARA = 1
macdef NK_H1 = 2
macdef NK_H2 = 3
macdef NK_H3 = 4
macdef NK_H4 = 5
macdef NK_H5 = 6
macdef NK_H6 = 7
macdef NK_UL = 8
macdef NK_OL = 9
macdef NK_LI = 10
macdef NK_QUOTE = 11
macdef NK_CODE = 12
macdef NK_HR = 13
macdef NK_TABLE = 14
macdef NK_TEXT = 15
macdef NK_WIKI = 16
macdef NK_EMBED = 17
macdef NK_TAG = 18
macdef NK_TASK = 19
macdef NK_FN = 20
macdef NK_FNDEF = 21
macdef NK_HIGH = 22
macdef NK_MATH = 23
macdef NK_MATHB = 24
macdef NK_FM = 25
macdef NK_IMAGE = 26
macdef NK_TD = 27
macdef NK_BOLD = 28
macdef NK_ITALIC = 29
macdef NK_STRIKE = 30
macdef NK_LINK = 31

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
macdef NF_Y = 13

macdef TASK_STATE_TODO = 32
macdef TASK_STATE_DONE = 120
macdef TASK_STATE_DONE_UPPER = 88
macdef TASK_STATE_PROGRESS = 47

fun doc_node_kind(d: !Doc, i: int): int
fun doc_node_start(d: !Doc, i: int): int
fun doc_node_end(d: !Doc, i: int): int
fun doc_node_depth(d: !Doc, i: int): int
fun doc_node_collapsed(d: !Doc, i: int): Toggle
fun doc_node_height(d: !Doc, i: int): int
fun doc_node_parent(d: !Doc, i: int): int
fun doc_node_hidden(d: !Doc, i: int): Toggle
fun doc_node_aux(d: !Doc, i: int): int
fun doc_node_y(d: !Doc, i: int): int

fun doc_open(): Doc
fun doc_is_md(d: !Doc): Toggle
fun doc_set_md(d: !Doc, is_md: Toggle): void
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
fun doc_load(d: !Doc, path: string): int
fun doc_load_checked(d: !Doc, path: string): int
fun doc_save(d: !Doc, path: string): int
fun doc_save_vfs(d: !Doc, path: string): int
fun doc_save_physical(d: !Doc, path: string): int
fun doc_nlines(d: !Doc): int
fun doc_line_start(d: !Doc, i: int): int
fun doc_line_y(d: !Doc, i: int): int
fun doc_line_of(d: !Doc, off: int): int
fun doc_nnodes(d: !Doc): int
fun doc_get(d: !Doc, i: int, f: int): int
fun doc_set(d: !Doc, i: int, f: int, v: int): void
fun doc_push_node(d: !Doc, kind: int, st: int, en: int, depth: int, aux: int): void
fun doc_toggle(d: !Doc, i: int): void
fun doc_toggle_task(d: !Doc, i: int): void
fun doc_span(d: !Doc): int
fun doc_layout(d: !Doc, lh: int): int
fun column_w(avail: int): int
fun column_x(pane: int, avail: int): int
fun doc_selftest(): int
