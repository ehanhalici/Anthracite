#include "data_font/glyph/substitution/glyph_substitution_stack_internal.hats"
fun check{n:nat} .<n>. (left: int(n),stack: !GlyphSubstitutionStack,lookup: int,node: int,
  generation: int,remaining: &int >> int): GlyphPassStatus =
  if left = 0 then GlyphPassApplied() else if ile(remaining,0) then GlyphPassCapacity() else let
    val ()=remaining := isub(remaining,1)
    val frame=glyph_substitution_stack_get(stack,left-1)
  in if ieq(frame.lookup,lookup) andalso ieq(frame.node,node) andalso ieq(frame.generation,generation)
    then GlyphPassReference() else check(left-1,stack,lookup,node,generation,remaining) end
implement glyph_substitution_stack_cycle(stack,depth,lookup,node,generation,remaining) =
  check(airlock_nat(depth),stack,lookup,node,generation,remaining)
