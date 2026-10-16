(* Private capability contract: Numeric operations shared by font modules. *)
staload "mem.sats"
staload "flag.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/core/glyph_component.sats"

fun bit(a: int, m: int): int
fun iround(d: double): int
fun font_mod(a: int, m: int): int
