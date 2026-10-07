staload "mem.sats"

absviewtype Doc = ptr

macdef NS = 16
macdef NK_PARA = 1
macdef NK_H1 = 2
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

fun doc_open(): Doc
fun doc_is_md(d: !Doc): int
fun doc_set_md(d: !Doc, is_md: int): void
fun doc_free(d: Doc): void
fun doc_len(d: !Doc): int
fun doc_caret(d: !Doc): int
fun doc_anchor(d: !Doc): int
fun doc_set_caret(d: !Doc, i: int, keep: int): void
fun doc_insert(d: !Doc, p: ptr, n: int): void
fun doc_backspace(d: !Doc): void
fun doc_delete(d: !Doc): void
fun doc_undo(d: !Doc): void
fun doc_redo(d: !Doc): void
fun doc_wrap(d: !Doc, pre: string, plen: int, suf: string, suflen: int): void
fun doc_left(d: !Doc): void
fun doc_right(d: !Doc): void
fun doc_up(d: !Doc): void
fun doc_down(d: !Doc): void
fun doc_home(d: !Doc): void
fun doc_end(d: !Doc): void
fun doc_left_k(d: !Doc, keep: int): void
fun doc_right_k(d: !Doc, keep: int): void
fun doc_up_k(d: !Doc, keep: int): void
fun doc_down_k(d: !Doc, keep: int): void
fun doc_home_k(d: !Doc, keep: int): void
fun doc_end_k(d: !Doc, keep: int): void
fun doc_word_left(d: !Doc, keep: int): void
fun doc_word_right(d: !Doc, keep: int): void
fun doc_del_word_left(d: !Doc): void
fun doc_del_word_right(d: !Doc): void
fun doc_doc_start(d: !Doc, keep: int): void
fun doc_doc_end(d: !Doc, keep: int): void
fun doc_page_up(d: !Doc, nlines: int, keep: int): void
fun doc_page_down(d: !Doc, nlines: int, keep: int): void
fun doc_byte(d: !Doc, i: int): int
fun doc_slice(d: !Doc, a: int, b: int, dst: ptr, cap: int): int
fun doc_text(d: !Doc, dst: &Buf >> _): void
fun doc_load(d: !Doc, path: string): int
fun doc_save(d: !Doc, path: string): int
fun doc_save_vfs(d: !Doc, path: string): int
fun doc_save_physical(d: !Doc, path: string): int
fun doc_nlines(d: !Doc): int
fun doc_line_start(d: !Doc, i: int): int
fun doc_line_y(d: !Doc, i: int): int
fun doc_line_step(d: !Doc, i: int): int
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
