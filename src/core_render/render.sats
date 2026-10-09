staload "mem.sats"

absviewtype Rend = ptr

datatype Shade = ShadeNone | ShadeSolid | ShadeAlpha | ShadeRgba

fun rend_open(): Rend
fun rend_close(r: Rend): void
fun rend_begin(r: !Rend, w: int, h: int): void
fun rend_flush(r: !Rend): void
fun rend_rect(r: !Rend, x: int, y: int, w: int, h: int, c: uint): void
fun rend_quad(r: !Rend, tex: uint, mode: Shade, x: int, y: int, w: int, h: int,
  u0: double, v0: double, u1: double, v1: double, c: uint): void
fun rend_scissor(r: !Rend, x: int, y: int, w: int, h: int): void
fun rend_scissor_off(r: !Rend): void
fun rend_tex_r8(r: !Rend, tex: uint, w: int, h: int): uint
fun rend_tex_sub_r8(r: !Rend, tex: uint, x: int, y: int, w: int, h: int, pixels: ptr): void
fun rend_tex_sub_buf(r: !Rend, tex: uint, x: int, y: int, w: int, h: int, pixels: !Buf, off: int): void
fun rend_tex_rgba(r: !Rend, w: int, h: int, pixels: ptr): uint
fun rend_tex_buf(r: !Rend, w: int, h: int, pixels: !Buf): uint
fun rend_tex_free(tex: uint): void
