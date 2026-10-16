(* Private capability contract: Scanline coverage and supersample reduction. *)
staload "mem.sats"
staload "flag.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/core/glyph_component.sats"

fun scan_rows(f: !Font, sw: int, sh: int, y: int): void
fun blit(f: !Font, x0: int, y0: int, sw: int, bw: int, bh: int, y: int): void
