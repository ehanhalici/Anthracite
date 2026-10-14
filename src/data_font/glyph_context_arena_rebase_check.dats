#include "data_font/glyph_context_arena_internal.hats"
staload "data_font/glyph_context_arena_rebase_work.sats"
implement glyph_context_arena_chain_valid(arena,chain) = let val+ GlyphContextArena(rows,used,maximum)=arena
in if ieq(chain.count,0) then ieq(chain.head,~1) andalso ieq(chain.tail,~1)
  else igt(chain.count,0) andalso ile(chain.count,used) andalso glyph_context_arena_valid(arena,chain.head)
    andalso glyph_context_arena_valid(arena,chain.tail) end
fun check{n,k:nat} .<k>. (left: int(k),s: !GlyphStorage(n),meta: GlyphRunMeta,node: int,
  remaining: &int >> int): GlyphPassStatus =
  if left = 0 then GlyphPassApplied()
  else if ile(remaining,0) then GlyphPassCapacity() else let
    val ()=remaining := isub(remaining,1)
  in if not(glyph_run_node(s,meta,node)) then GlyphPassReference()
    else check(left-1,s,meta,iadd(node,1),remaining) end
implement glyph_context_arena_insertion_valid(s,meta,insertion,remaining) =
  if ilt(insertion.added,0) orelse ilt(insertion.first,0) orelse igt(insertion.first,meta.used)
    orelse igt(insertion.added,isub(meta.used,insertion.first)) then GlyphPassReference()
  else if igt(insertion.added,0) andalso not(glyph_run_node(s,meta,insertion.node)) then GlyphPassReference()
  else check(airlock_nat(insertion.added),s,meta,insertion.first,remaining)
