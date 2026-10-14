#include "data_font/glyph_context_arena_internal.hats"
fun write(arena: &GlyphContextArena >> GlyphContextArena,node: int,remaining: &int >> int): GlyphContextSlot = let
  val+ @GlyphContextArena(rows,used,maximum)=arena
  val id=used
  val ()=buf_ensure(rows,imul(iadd(used,1),8))
  val ()=buf_set32(rows,imul(id,2),node) and ()=buf_set32(rows,iadd(imul(id,2),1),~1)
  val ()=used := iadd(used,1)
  val ()=buf_set_len(rows,imul(used,8))
  val ()=remaining := isub(remaining,1)
  prval ()=fold@(arena)
in @{status=GlyphPassApplied(),id=id} end
implement glyph_context_arena_append(arena,node,remaining) = let val+ GlyphContextArena(rows,used,maximum)=arena
in if ilt(node,0) then @{status=GlyphPassReference(),id= ~1}
  else if ige(used,maximum) orelse ile(remaining,0) then @{status=GlyphPassCapacity(),id= ~1}
  else write(arena,node,remaining) end
implement glyph_context_chain_empty() = @{head= ~1,tail= ~1,count=0}
implement glyph_context_chain_push(arena,chain,id) = let val ()=glyph_context_chain_join(arena,chain.tail,id)
in @{head=if ieq(chain.count,0) then id else chain.head,tail=id,count=iadd(chain.count,1)} end
implement glyph_context_chain_join(arena,previous,next) =
  if ieq(previous,~1) then () else glyph_context_arena_link(arena,previous,next)
