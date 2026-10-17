#include "font/glyph/context/glyph_context_arena_test.hats"
fun append{n:nat} .<n>. (left: int(n),arena: &GlyphContextArena >> GlyphContextArena,chain: GlyphContextChain,
  node: int,remaining: &int >> int): GlyphContextChainRead =
  if left = 0 then @{status=GlyphPassApplied(),chain=chain} else let
    val slot=glyph_context_arena_append(arena,node,remaining)
    val next=glyph_context_chain_push(arena,chain,slot.id)
  in append(left-1,arena,next,iadd(node,1),remaining) end
implement context_arena_stress() = let
  var arena: GlyphContextArena=glyph_context_arena_make(WORD16_SIGN_BIT)
  var remaining: int=WORD16_MODULUS
  val chain=append(WORD16_SIGN_BIT,arena,glyph_context_chain_empty(),0,remaining)
  val last=glyph_context_arena_node(arena,chain.chain,32767,remaining)
  val ok=reverse_pass_ready(chain.status) andalso reverse_pass_ready(last.status)
    andalso ieq(chain.chain.count,WORD16_SIGN_BIT) andalso ieq(last.node,32767) andalso ieq(remaining,0)
  val ()=glyph_context_arena_dispose(arena)
in if ok then 0 else 1 end
