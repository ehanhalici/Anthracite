(* Private capability contract: Decoding Type 2 CFF glyph outlines. *)
staload "mem.sats"
staload "flag.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/core/glyph_component.sats"

fun load_cff_outline(f: !Font, gid: int): void
