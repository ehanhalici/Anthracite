(* Private capability contract: Legacy kerning pair search. *)
staload "mem.sats"
staload "flag.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"
staload "data_font/sfnt.sats"
staload "data_font/glyph_component.sats"

fun kern_search(b: !Buf, off: int, n: int, left: int, right: int, lo: int, hi: int): int
