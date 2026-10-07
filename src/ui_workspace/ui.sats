staload "mem.sats"
staload "core_platform/platform.sats"
staload "core_platform/x11.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"

absviewtype App = ptr

fun app_open(vault: string): App
fun app_free(a: App): void
fun app_draw(a: !App, f: !Font, r: !Rend, w: int, h: int): void
fun app_event(a: !App, p: !Plat, f: !Font, r: !Rend, ev: &event, w: int, h: int): void
fun app_selftest(r: !Rend): int
