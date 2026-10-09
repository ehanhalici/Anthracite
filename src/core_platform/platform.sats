staload "flag.sats"
staload "core_platform/x11.sats"

absviewtype Plat = ptr

fun plat_open(): Plat
fun plat_close(p: Plat): void
fun plat_ok(p: !Plat): int
fun plat_wh(p: !Plat, w: &int >> _, h: &int >> _): void
fun plat_set_wh(p: !Plat, w: int, h: int): void
fun plat_running(p: !Plat): Toggle
fun plat_stop(p: !Plat): void
fun plat_pending(p: !Plat): int
fun plat_wait(p: !Plat, ms: int): int
fun plat_next(p: !Plat, ev: &event? >> event): void
fun plat_ensure_im(p: !Plat): void
fun plat_swap(p: !Plat): void
fun plat_own(p: !Plat, primary: int): void
fun plat_paste(p: !Plat, primary: int): void
fun plat_reply(p: !Plat, ev: &event, data: ptr, n: int): void
fun plat_read(p: !Plat, ev: &event, dst: ptr, cap: int): int
