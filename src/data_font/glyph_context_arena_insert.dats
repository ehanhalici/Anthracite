#include "data_font/glyph_context_arena_internal.hats"
fun insert{n:nat} .<n>. (left: int(n),arena: &GlyphContextArena >> GlyphContextArena,node: int,
  chain: GlyphContextChain,remaining: &int >> int): GlyphContextChainRead =
  if left = 0 then @{status=GlyphPassApplied(),chain=chain} else let
    val entry=glyph_context_arena_append(arena,node,remaining)
  in case+ entry.status of
    | GlyphPassApplied() => let val next=glyph_context_chain_push(arena,chain,entry.id)
      in insert(left-1,arena,iadd(node,1),next,remaining) end
    | GlyphPassDomain() => @{status=entry.status,chain=chain} | GlyphPassReference() => @{status=entry.status,chain=chain}
    | GlyphPassCapacity() => @{status=entry.status,chain=chain} end
implement glyph_context_arena_insert(arena,insertion,remaining) =
  insert(airlock_nat(insertion.added),arena,insertion.first,glyph_context_chain_empty(),remaining)
