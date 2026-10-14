staload "mem.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_context_arena_types.sats"
fun glyph_context_arena_append(arena: &GlyphContextArena >> GlyphContextArena,node: int,remaining: &int >> int): GlyphContextSlot
fun glyph_context_arena_valid(arena: !GlyphContextArena,id: int): bool
fun glyph_context_arena_value(arena: !GlyphContextArena,id: int): int
fun glyph_context_arena_next(arena: !GlyphContextArena,id: int): int
fun glyph_context_arena_link(arena: !GlyphContextArena,id: int,next: int): void
fun glyph_context_chain_push(arena: !GlyphContextArena,chain: GlyphContextChain,id: int): GlyphContextChain
fun glyph_context_chain_join(arena: !GlyphContextArena,previous: int,next: int): void
fun glyph_context_arena_insert(arena: &GlyphContextArena >> GlyphContextArena,insertion: GlyphContextInsertion,
  remaining: &int >> int): GlyphContextChainRead
