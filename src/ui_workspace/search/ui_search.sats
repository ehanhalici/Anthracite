staload "mem.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"
staload "search/literal/literal_search.sats"
staload "ui_workspace/common/ui_common.sats"
macdef SEARCH_SCOPE_VAULT = 0
macdef SEARCH_SCOPE_DOCUMENT = 1
macdef SEARCH_IDLE = 0
macdef SEARCH_RUNNING = 1
macdef SEARCH_PARTIAL = 2
macdef SEARCH_UNAVAILABLE = 3
macdef SEARCH_WORK_BUDGET_NS = 4000000L
macdef SEARCH_FLASH_DURATION_NS = UI_NAVIGATION_FLASH_NS
typedef SearchGeometry = @{buttonTop=int,buttonHeight=int,buttonWidth=int,secondX=int,secondY=int,
  queryTop=int,queryHeight=int,statusTop=int,resultsTop=int,rowHeight=int,rows=int}
fun search_geometry(line_height: int,width: int,height: int): SearchGeometry
fun search_scope_hit(geometry: SearchGeometry,x: int,y: int): int
fun search_visible_hit(geometry: SearchGeometry,y: int,scroll: int): int
fun search_flash_wait(now: lint,deadline: lint): int
fun literal_pattern_open_default(query: !Buf): Option_vt(LiteralPattern)

fun search_dir(path: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, depth: int): void
fun refresh_search(vault: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _): void
fun find_hit_file(hmeta: !Buf, hits: !Buf, row: int, dst: &Buf >> _): void
fun hit_text(hits: !Buf, off: int, n: int, f: !Font, r: !Rend, x: int, y: int, c: uint): int
