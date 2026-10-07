staload "mem.sats"
staload "core_render/render.sats"

absviewtype Image = ptr

fun img_open(): Image
fun img_free(im: Image): void
fun img_load(im: !Image, path: string): int
fun img_w(im: !Image): int
fun img_h(im: !Image): int
fun img_ptr(im: !Image): ptr
fun img_ok(im: !Image): int
fun img_upload(im: !Image, r: !Rend): uint
fun img_selftest(): int
