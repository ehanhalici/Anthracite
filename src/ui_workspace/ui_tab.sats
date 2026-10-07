staload "mem.sats"
staload "data_ast/doc.sats"

datavtype Tabs =
  | TNil of ()
  | TCons of (Doc, Buf, Buf, int, Tabs)

datavtype Pair = PAIR of (Tabs, Tabs)

fun tabs_free(ts: Tabs): void
fun tabs_len(ts: !Tabs): int
fun tabs_drop(ts: Tabs, i: int): Tabs
fun tabs_add(ts: Tabs, doc: Doc, path: Buf, title: Buf): Tabs
fun tabs_append(ts: Tabs, doc: Doc, path: Buf, title: Buf, sc: int): Tabs
fun tabs_cmd(ts: Tabs, idx: int, cmd: int): Tabs
fun tabs_ins(ts: Tabs, idx: int, p: ptr, n: int): Tabs
fun tabs_scroll(ts: Tabs, idx: int, dv: int, lim: int): Tabs
fun tabs_save(ts: Tabs, idx: int, vault: !Buf): Tabs
fun tabs_text(ts: !Tabs, idx: int, dst: &Buf >> _): void
fun tabs_slice(ts: !Tabs, idx: int, a: int, b: int, dst: &Buf >> _): int
fun tabs_copy(ts: !Tabs, idx: int, dst: &Buf >> _): void
fun tabs_open(ts: Tabs, path: Buf): Tabs
fun tabs_detach(ts: Tabs, i: int): Pair
fun tabs_link(one: Tabs, ts: Tabs): Tabs
fun tabs_insert(ts: Tabs, i: int, one: Tabs): Tabs
fun tabs_toggle(ts: Tabs, idx: int, ni: int): Tabs
fun tabs_toggle_task(ts: Tabs, idx: int, ni: int): Tabs
fun tabs_sync_vfs(ts: !Tabs, idx: int): void
fun tabs_save_all_physical(ts: !Tabs): void
fun tabs_ensure_paths(ts: Tabs, vault: !Buf): Tabs
fun touch_doc(d: !Doc): int
