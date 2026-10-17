#include "data_font/glyph/substitution/glyph_substitution_stack_internal.hats"
implement glyph_substitution_frame_enter(lookup,node,generation) = let val empty=glyph_substitution_unchanged(~1)
in @{state=SubstitutionEnter(),lookup=lookup,node=node,action=0,next= ~1,generation=generation,
  matched=false,context=empty.context,chain=empty.chain} end
implement glyph_substitution_frame_empty() = glyph_substitution_frame_enter(~1,~1,0)
implement glyph_substitution_frame_nested(old,step) =
  @{state=SubstitutionActions(),lookup=old.lookup,node=old.node,action=0,next=step.next,generation=old.generation,
    matched=step.matched,context=step.context,chain=step.chain}
implement glyph_substitution_frame_action(old) =
  @{state=old.state,lookup=old.lookup,node=old.node,action=iadd(old.action,1),next=old.next,generation=old.generation,
    matched=old.matched,context=old.context,chain=old.chain}
implement glyph_substitution_frame_chain(old,chain) =
  @{state=old.state,lookup=old.lookup,node=old.node,action=old.action,next=old.next,generation=old.generation,
    matched=old.matched,context=old.context,chain=chain}
