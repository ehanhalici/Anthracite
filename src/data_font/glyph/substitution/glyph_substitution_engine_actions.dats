#include "data_font/glyph/substitution/glyph_substitution_engine_internal.hats"
staload "data_font/opentype/context/ot_context.sats"
fun push(stack: &GlyphSubstitutionStack >> GlyphSubstitutionStack,frame: GlyphSubstitutionFrame,
  depth: int,lookup: int,node: int,generation: int): GlyphSubstitutionEvent = let
  val status=glyph_substitution_stack_reserve(stack,iadd(depth,2))
in if not(glyph_substitution_ready(status)) then glyph_substitution_event_fault(status) else let
  val ()=glyph_substitution_stack_set(stack,depth,glyph_substitution_frame_action(frame))
  val ()=glyph_substitution_stack_set(stack,iadd(depth,1),glyph_substitution_frame_enter(lookup,node,generation))
in glyph_substitution_event_continue(iadd(depth,1)) end end
fun action(b: !Buf,frame: GlyphSubstitutionFrame,stack: &GlyphSubstitutionStack >> GlyphSubstitutionStack,
  arena: !GlyphContextArena,depth: int,generation: int,remaining: &int >> int): GlyphSubstitutionEvent = let
  val lookup=ot_context_action(b,frame.context,frame.action)
in if ige(lookup.position,frame.chain.count) then let
    val ()=glyph_substitution_stack_set(stack,depth,glyph_substitution_frame_action(frame))
  in glyph_substitution_event_continue(depth) end else let
    val target=glyph_context_arena_node(arena,frame.chain,lookup.position,remaining)
  in if glyph_substitution_ready(target.status) then push(stack,frame,depth,lookup.lookup,target.node,generation)
    else glyph_substitution_event_fault(target.status) end end
implement glyph_substitution_actions(b,run,w,depth,generation,remaining) = let
  val+ @GlyphSubstitutionWorkspace(window,stack,arena,output,glyphs,nodes,weights,maximum)=w
  val frame=glyph_substitution_stack_get(stack,depth)
  val event=if ilt(frame.action,frame.context.actionCount) then action(b,frame,stack,arena,depth,generation,remaining) else let
    val next=glyph_substitution_next(run,frame.next,remaining)
  in if glyph_substitution_ready(next.status) then glyph_substitution_event_done(depth,next.node,frame.matched)
    else glyph_substitution_event_fault(next.status) end
  prval ()=fold@(w)
in event end
