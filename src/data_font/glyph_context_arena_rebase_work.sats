staload "data_font/glyph_context_arena_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_run_types.sats"
typedef GlyphContextRebaseStep = @{status=GlyphPassStatus,previous=int,chain=GlyphContextChain}
fun glyph_context_arena_remove(arena: !GlyphContextArena,chain: GlyphContextChain,id: int,
  previous: int,next: int): GlyphContextChain
fun glyph_context_arena_splice(arena: !GlyphContextArena,chain: GlyphContextChain,id: int,
  next: int,inserted: GlyphContextChain): GlyphContextChain
fun glyph_context_arena_rebase_step{n:nat}(arena: &GlyphContextArena >> GlyphContextArena,
  chain: GlyphContextChain,s: !GlyphStorage(n),meta: GlyphRunMeta,id: int,previous: int,next: int,
  insertion: GlyphContextInsertion,remaining: &int >> int): GlyphContextRebaseStep
fun glyph_context_arena_chain_valid(arena: !GlyphContextArena,chain: GlyphContextChain): bool
fun glyph_context_arena_insertion_valid{n:nat}(s: !GlyphStorage(n),meta: GlyphRunMeta,
  insertion: GlyphContextInsertion,remaining: &int >> int): GlyphPassStatus
