#include "data_font/glyph/context/glyph_context_arena_internal.hats"
fun capture{n:nat} .<n>. (left: int(n),arena: &GlyphContextArena >> GlyphContextArena,w: !GlyphContextWindow,
  span: GlyphWindowSpan,index: int,chain: GlyphContextChain,remaining: &int >> int): GlyphContextChainRead =
  if left = 0 then @{status=GlyphPassApplied(),chain=chain} else let
    val node=glyph_window_node(w,span,index)
    val entry=glyph_context_arena_append(arena,node,remaining)
  in case+ entry.status of
    | GlyphPassApplied() => let val next=glyph_context_chain_push(arena,chain,entry.id)
      in capture(left-1,arena,w,span,iadd(index,1),next,remaining) end
    | GlyphPassDomain() => @{status=entry.status,chain=chain} | GlyphPassReference() => @{status=entry.status,chain=chain}
    | GlyphPassCapacity() => @{status=entry.status,chain=chain} end
implement glyph_context_arena_capture(arena,w,span,count,remaining) =
  if ilt(count,1) orelse igt(count,span.input) then @{status=GlyphPassReference(),chain=glyph_context_chain_empty()}
  else capture(airlock_nat(count),arena,w,span,0,glyph_context_chain_empty(),remaining)
fun walk{n:nat} .<n>. (left: int(n),arena: !GlyphContextArena,id: int,remaining: &int >> int): GlyphContextNode =
  if not(glyph_context_arena_valid(arena,id)) then @{status=GlyphPassReference(),node= ~1}
  else if ile(remaining,0) then @{status=GlyphPassCapacity(),node= ~1}
  else if left = 0 then let val ()=remaining := isub(remaining,1)
    in @{status=GlyphPassApplied(),node=glyph_context_arena_value(arena,id)} end else let
      val ()=remaining := isub(remaining,1)
    in walk(left-1,arena,glyph_context_arena_next(arena,id),remaining) end
implement glyph_context_arena_node(arena,chain,index,remaining) =
  if ilt(index,0) orelse ige(index,chain.count) then @{status=GlyphPassReference(),node= ~1}
  else walk(airlock_nat(index),arena,chain.head,remaining)
