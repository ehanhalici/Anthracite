(* Private capability contract: Scanline coverage and supersample reduction. *)
staload "mem.sats"
staload "flag.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/core/glyph_component.sats"

fun raster_scan_to_atlas(f: !Font, x0: int, y0: int, bw: int, bh: int): void
