(* Private capability contract: TrueType glyph rasterization orchestration. *)
staload "mem.sats"
staload "flag.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/core/glyph_component.sats"

fun raster_ttf(f: !Font, r: !Rend, gid: int, g: &gmet >> _): void
