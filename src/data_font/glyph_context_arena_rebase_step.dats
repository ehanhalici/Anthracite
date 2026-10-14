#include "data_font/glyph_context_arena_internal.hats"
staload "data_font/glyph_context_arena_rebase_work.sats"
implement glyph_context_arena_remove(arena,chain,id,previous,next) = let
  val ()=glyph_context_chain_join(arena,previous,next)
in @{head=if ieq(chain.head,id) then next else chain.head,
  tail=if ieq(chain.tail,id) then previous else chain.tail,count=isub(chain.count,1)} end
implement glyph_context_arena_splice(arena,chain,id,next,inserted) = let
  val ()=glyph_context_arena_link(arena,id,inserted.head)
  val ()=glyph_context_arena_link(arena,inserted.tail,next)
in @{head=chain.head,tail=if ieq(chain.tail,id) then inserted.tail else chain.tail,count=iadd(chain.count,inserted.count)} end
fun insert(arena: &GlyphContextArena >> GlyphContextArena,chain: GlyphContextChain,id: int,next: int,
  insertion: GlyphContextInsertion,remaining: &int >> int): GlyphContextRebaseStep = let
  val r=glyph_context_arena_insert(arena,insertion,remaining)
in case+ r.status of | GlyphPassApplied() => @{status=r.status,previous=r.chain.tail,
    chain=glyph_context_arena_splice(arena,chain,id,next,r.chain)}
  | GlyphPassDomain() => @{status=r.status,previous=id,chain=chain}
  | GlyphPassReference() => @{status=r.status,previous=id,chain=chain}
  | GlyphPassCapacity() => @{status=r.status,previous=id,chain=chain} end
implement glyph_context_arena_rebase_step(arena,chain,s,meta,id,previous,next,insertion,remaining) = let
  val node=glyph_context_arena_value(arena,id)
in if ilt(node,0) orelse ige(node,meta.used) then @{status=GlyphPassReference(),previous=previous,chain=chain}
  else let val links=glyph_storage_links(s,node) in case+ links.life of
  | GlyphRemoved() => @{status=GlyphPassApplied(),previous=previous,
    chain=glyph_context_arena_remove(arena,chain,id,previous,next)}
  | GlyphVacant() => @{status=GlyphPassReference(),previous=previous,chain=chain}
  | GlyphLive() => if ieq(node,insertion.node) andalso igt(insertion.added,0) then insert(arena,chain,id,next,insertion,remaining)
    else @{status=GlyphPassApplied(),previous=id,chain=chain} end end
