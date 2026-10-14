(* Private capability contract: Font size and line metric configuration. *)
staload "mem.sats"
staload "flag.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"
staload "data_font/sfnt.sats"
staload "data_font/glyph_component.sats"

fun store_ttf_metrics(f: !Font): void
fun scale_of(f: !Font): double
