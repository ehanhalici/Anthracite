(* Private capability contract: Bitmap fallback glyph rasterization. *)
staload "mem.sats"
staload "flag.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/core/glyph_component.sats"

fun raster_bitmap(f: !Font, r: !Rend, cp: int, g: &gmet >> _): void
