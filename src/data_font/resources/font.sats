staload "mem.sats"
staload "flag.sats"
staload "core_render/render.sats"

typedef gmet = @{
  ax= int, bx= int, top= int, bw= int, bh= int, x0= int, y0= int, ok= Toggle
}

absviewtype Font = ptr

fun font_open(): Font
fun font_free(f: Font): void
fun font_use_file(f: !Font, path: string): bool
fun font_use_fallback_file(f: !Font, path: string): bool
fun font_load_default(f: !Font): bool
fun font_has_ttf(f: !Font): Toggle
fun font_set_px(f: !Font, px: int): void
fun font_line_h(f: !Font): int
fun font_asc(f: !Font): int
fun font_tex(f: !Font): uint
fun font_atlas_w(f: !Font): int
fun font_atlas_h(f: !Font): int
fun font_glyph(f: !Font, r: !Rend, cp: int, g: &gmet >> _): void
fun font_kern(f: !Font, a: int, b: int): int
fun font_draw(f: !Font, r: !Rend, x: int, y: int, p: ptr, n: int, c: uint): int
fun font_draw_buf(f: !Font, r: !Rend, x: int, y: int, b: !Buf, n: int, c: uint): int
fun font_draw_at(f: !Font, r: !Rend, x: int, y: int, b: !Buf, i: int, n: int, c: uint): int
fun font_draw_scaled(f: !Font, r: !Rend, x: int, y: int, p: ptr, n: int, c: uint, snum: int, sden: int): int
fun font_draw_scaled_buf(f: !Font, r: !Rend, x: int, y: int, b: !Buf, n: int, c: uint, snum: int, sden: int): int
fun font_width(f: !Font, r: !Rend, p: ptr, n: int): int
fun font_width_buf(f: !Font, r: !Rend, b: !Buf, n: int): int
fun font_scan_fonts(dir: string, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _): void
fun font_selftest(r: !Rend): int
