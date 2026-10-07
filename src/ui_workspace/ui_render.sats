staload "mem.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"
staload "data_ast/doc.sats"
staload "ui_workspace/ui_tab.sats"

datavtype Cache =
  | CNil of ()
  | CCons of (Buf, uint, int, int, Cache)

fun cache_free(c: Cache): void
fun draw_doc(f: !Font, r: !Rend, d: !Doc, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, viewmode: int): int
fun draw_tabrow(f: !Font, r: !Rend, ts: Tabs, x: int, active: int, i: int): Tabs
fun tab_hit_test(f: !Font, r: !Rend, ts: !Tabs, start_x: int, click_x: int, out_ti: &int >> _, out_close: &int >> _): void
fun draw_focus(f: !Font, r: !Rend, ts: Tabs, idx: int, ox: int, oy: int, pw: int, ph: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, i: int, viewmode: int): Tabs
fun draw_right(f: !Font, r: !Rend, ts: Tabs, split: int, idx: int, ox: int, oy: int, pw: int, ph: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, viewmode: int): Tabs
fun tabs_click(f: !Font, r: !Rend, ts: Tabs, idx: int, x: int, y: int, ox: int, pw: int, scroll_hint: int, lh: int, scratch: &Buf >> _, keep: int, hitk: &int >> _, hiti: &int >> _, i: int): Tabs
fun caret_xy(f: !Font, r: !Rend, d: !Doc, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _, cx: &int >> _, cy: &int >> _): void
fun take_path(d: !Doc, i: int, dst: &Buf >> _): void
fun resolve_path(vault: !Buf, rel: !Buf, dst: &Buf >> _): void
fun with_md(path: !Buf, dst: &Buf >> _): void
fun read_or(b: !Buf, fd: int, sz: int): int
fun prep_doc(d: !Doc, c: &Cache >> _, r: !Rend, vault: !Buf, lh: int, colw: int): int
fun node_covering(d: !Doc, y: int, oy: int, scroll: int, i: int, best: int): int
fun draw_nodes(f: !Font, r: !Rend, d: !Doc, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, i: int, py: &int >> _, pa: &int >> _, viewmode: int): void
