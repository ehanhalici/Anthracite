(* Private capability contract: Atlas packing and texture upload orchestration. *)
staload "mem.sats"
staload "flag.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"
staload "data_font/sfnt.sats"
staload "data_font/glyph_component.sats"

fun clamp_even(n: int): int
typedef FontAtlasSlot = @{x=int,y=int,row=int,reset=bool}
fun font_atlas_plan(f: !Font,bw: int,bh: int): FontAtlasSlot
fun reserve(f: !Font, r: !Rend, bw: int, bh: int, x: &int >> _, y: &int >> _): void
fun upload(f: !Font, r: !Rend, x: int, y: int, w: int, h: int): void
