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
fun rend_quad_pixels(r: !Rend,tex: uint,mode: Shade,x: double,y: double,w: double,h: double,
  u0: double,v0: double,u1: double,v1: double,c: uint): void
fun rend_scissor(r: !Rend, x: int, y: int, w: int, h: int): void
fun rend_scissor_off(r: !Rend): void
(* Nested clips only restrict the current parent; pop restores it exactly. *)
typedef RenderClip = @{x=int,y=int,width=int,height=int}
fun render_clip_intersection(parent: RenderClip,child: RenderClip): RenderClip
fun rend_clip_push(r: !Rend,x: int,y: int,width: int,height: int): void
fun rend_clip_pop(r: !Rend): void
fun rend_capture(r: !Rend): void
fun rend_blur_rect(r: !Rend, x: int, y: int, w: int, h: int, radius: int): void
fun rend_tex_r8(r: !Rend, tex: uint, w: int, h: int): uint
fun rend_tex_sub_r8(r: !Rend, tex: uint, x: int, y: int, w: int, h: int, pixels: ptr): void
fun rend_tex_sub_buf(r: !Rend, tex: uint, x: int, y: int, w: int, h: int, pixels: !Buf, off: int): void
fun rend_tex_rgba(r: !Rend, w: int, h: int, pixels: ptr): uint
fun rend_tex_buf(r: !Rend, w: int, h: int, pixels: !Buf): uint
fun rend_tex_free(tex: uint): void
