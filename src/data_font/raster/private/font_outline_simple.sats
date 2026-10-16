(* Private capability contract: Decoding simple TrueType contours. *)
staload "mem.sats"
staload "flag.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/core/glyph_component.sats"

fun decode_simple(f: !Font, p0: int, ncont: int, dx: double, dy: double, xx: double, yy: double, xy: double, yx: double): void
