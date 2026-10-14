#include "data_font/glyph_context_arena_internal.hats"
staload "data_font/glyph_context_arena_rebase_work.sats"
fun walk{n,k:nat} .<k>. (left: int(k),arena: &GlyphContextArena >> GlyphContextArena,chain: GlyphContextChain,
  s: !GlyphStorage(n),meta: GlyphRunMeta,id: int,previous: int,insertion: GlyphContextInsertion,
  remaining: &int >> int): GlyphContextChainRead =
  if left = 0 then @{status=if ieq(id,~1) andalso ieq(previous,chain.tail) then GlyphPassApplied() else GlyphPassReference(),chain=chain}
  else if not(glyph_context_arena_valid(arena,id)) then @{status=GlyphPassReference(),chain=chain}
  else if ile(remaining,0) then @{status=GlyphPassCapacity(),chain=chain} else let
    val ()=remaining := isub(remaining,1)
    val next=glyph_context_arena_next(arena,id)
    val r=glyph_context_arena_rebase_step(arena,chain,s,meta,id,previous,next,insertion,remaining)
  in case+ r.status of
    | GlyphPassApplied() => walk(left-1,arena,r.chain,s,meta,next,r.previous,insertion,remaining)
    | GlyphPassDomain() => @{status=r.status,chain=r.chain} | GlyphPassReference() => @{status=r.status,chain=r.chain}
    | GlyphPassCapacity() => @{status=r.status,chain=r.chain} end
implement glyph_context_arena_rebase(arena,chain,s,meta,insertion,remaining) =
  if not(glyph_context_arena_chain_valid(arena,chain)) then @{status=GlyphPassReference(),chain=chain}
  else case+ glyph_context_arena_insertion_valid(s,meta,insertion,remaining) of
    | GlyphPassApplied() => walk(airlock_nat(chain.count),arena,chain,s,meta,chain.head,~1,insertion,remaining)
    | GlyphPassDomain() => @{status=GlyphPassDomain(),chain=chain}
    | GlyphPassReference() => @{status=GlyphPassReference(),chain=chain}
    | GlyphPassCapacity() => @{status=GlyphPassCapacity(),chain=chain}
