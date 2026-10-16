staload "mem.sats"
staload "core_render/render.sats"

absviewtype Image = ptr

fun img_open(): Image
fun img_free(im: Image): void
fun img_load(im: !Image, path: string): int
fun img_load_at(im: !Image, path: string, file: string, line: int): int
fun image_width(im: !Image): int
fun image_height(im: !Image): int
fun img_upload(im: !Image, r: !Rend): uint
fun img_resize(im: !Image, target_w: int, target_h: int): int
fun img_selftest(): int
