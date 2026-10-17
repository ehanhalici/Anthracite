(* Private capability contract: Quadratic contour expansion and edge construction. *)
staload "mem.sats"
staload "flag.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/core/glyph_component.sats"

fun contours(f: !Font, ci: int, nends: int, minx: int, maxy: int, sc: double): void
fun bbox(f: !Font, i: int, n: int, minx: &int, miny: &int, maxx: &int, maxy: &int): void
