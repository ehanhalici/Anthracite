(* Private capability contract: Composing TrueType component outlines. *)
staload "mem.sats"
staload "flag.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"
staload "data_font/sfnt.sats"
staload "data_font/glyph_component.sats"

fun load_ttf_outline(f: !Font, gid: int): void
