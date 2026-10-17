(* Private capability contract: Glyph cache probing and entry management. *)
staload "mem.sats"
staload "flag.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/core/glyph_component.sats"
staload "data_font/atlas/private/font_cache_types.sats"

fun clear_cache(f: !Font, i: int): void
fun fill_g(g: &gmet >> _, ax: int, bx: int, top: int, bw: int, bh: int, x0: int, y0: int): void
fun cache_get(f: !Font, cp: int, g: &gmet >> _): int
fun cache_put(f: !Font, cp: int, g: &gmet): void
fun cache_get_key(f: !Font,key: FontCacheKey,g: &gmet >> _): int
fun cache_put_key(f: !Font,key: FontCacheKey,g: &gmet): void
