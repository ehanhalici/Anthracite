staload "mem.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"

fun search_dir(path: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, depth: int): void
fun refresh_search(vault: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _): void
fun find_hit_file(hmeta: !Buf, hits: !Buf, row: int, dst: &Buf >> _): void
fun hit_text(hits: !Buf, off: int, n: int, f: !Font, r: !Rend, x: int, y: int, c: uint): int
