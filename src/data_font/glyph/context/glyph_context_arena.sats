staload "mem.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_window_types.sats"
staload "data_font/glyph/context/glyph_context_arena_types.sats"
fun glyph_context_arena_make(maximum: int): GlyphContextArena
fun glyph_context_arena_dispose(arena: GlyphContextArena): void
fun glyph_context_arena_reset(arena: &GlyphContextArena >> GlyphContextArena): void
fun glyph_context_chain_empty(): GlyphContextChain
fun glyph_context_arena_capture(arena: &GlyphContextArena >> GlyphContextArena,w: !GlyphContextWindow,
  span: GlyphWindowSpan,count: int,remaining: &int >> int): GlyphContextChainRead
fun glyph_context_arena_node(arena: !GlyphContextArena,chain: GlyphContextChain,index: int,
  remaining: &int >> int): GlyphContextNode
(* Reconcile a completed child edit with each active parent's matched sequence.
   Surviving nodes retain their slot, removed nodes disappear, and Multiple's
   new nodes enter immediately after its preserved first node. Never re-filter
   the original match against the output glyph classes. *)
fun glyph_context_arena_rebase{n:nat}(arena: &GlyphContextArena >> GlyphContextArena,
  chain: GlyphContextChain,s: !GlyphStorage(n),meta: GlyphRunMeta,insertion: GlyphContextInsertion,
  remaining: &int >> int): GlyphContextChainRead
