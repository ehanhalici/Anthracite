#include "data_font/glyph_substitution_stack_internal.hats"
fun rebase(stack: !GlyphSubstitutionStack,index: int,arena: &GlyphContextArena >> GlyphContextArena,
  run: !GlyphRun(1),insertion: GlyphContextInsertion,remaining: &int >> int): GlyphPassStatus = let
  val frame=glyph_substitution_stack_get(stack,index)
  val+ GlyphRun(phase,meta,s)=run
  val result=glyph_context_arena_rebase(arena,frame.chain,s,meta,insertion,remaining)
  val ()=glyph_substitution_stack_set(stack,index,glyph_substitution_frame_chain(frame,result.chain))
in result.status end
fun frames{n:nat} .<n>. (left: int(n),stack: !GlyphSubstitutionStack,arena: &GlyphContextArena >> GlyphContextArena,
  run: !GlyphRun(1),insertion: GlyphContextInsertion,remaining: &int >> int): GlyphPassStatus =
  if left = 0 then GlyphPassApplied() else let val status=rebase(stack,left-1,arena,run,insertion,remaining)
  in case+ status of | GlyphPassApplied() => frames(left-1,stack,arena,run,insertion,remaining)
    | GlyphPassDomain() => status | GlyphPassReference() => status | GlyphPassCapacity() => status end
implement glyph_substitution_stack_rebase(stack,depth,arena,run,insertion,remaining) =
  frames(airlock_nat(depth),stack,arena,run,insertion,remaining)
