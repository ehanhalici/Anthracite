staload "mem.sats"
staload "ui_workspace/tabs/ui_tab.sats"

macdef MAX_TAB_HISTORY_ENTRIES = 64

datavtype HistEntryList =
  | HENil of ()
  | HECons of (Buf, int, int, HistEntryList)

datavtype TabHistList =
  | THNil of ()
  | THCons of (HistEntryList, int, TabHistList)

fun tab_hist_free(hl: TabHistList): void
fun tab_hist_len(hl: !TabHistList): int
fun tab_hist_sync(hl: TabHistList, ts: !Tabs): TabHistList
fun tab_hist_add(hl: TabHistList, path: !Buf, sc: int, caret: int): TabHistList
fun tab_hist_drop(hl: TabHistList, idx: int): TabHistList
fun tab_hist_move(hl: TabHistList, from_i: int, to_i: int): TabHistList
fun tab_hist_clone(hl: TabHistList, idx: int): TabHistList

fun tab_hist_can_back(hl: !TabHistList, idx: int): bool
fun tab_hist_can_forward(hl: !TabHistList, idx: int): bool

fun tab_hist_push(
  hl: TabHistList, idx: int,
  cur_path: !Buf, cur_sc: int, cur_caret: int,
  next_path: !Buf, next_sc: int, next_caret: int
): TabHistList

fun tab_hist_back(
  hl: TabHistList, idx: int,
  cur_path: !Buf, cur_sc: int, cur_caret: int,
  out_path: &Buf >> _, out_sc: &int >> _, out_caret: &int >> _
): @(TabHistList, bool)

fun tab_hist_forward(
  hl: TabHistList, idx: int,
  cur_path: !Buf, cur_sc: int, cur_caret: int,
  out_path: &Buf >> _, out_sc: &int >> _, out_caret: &int >> _
): @(TabHistList, bool)

fun tab_hist_rename_prefix(hl: TabHistList, old_p: !Buf, new_p: !Buf): TabHistList
