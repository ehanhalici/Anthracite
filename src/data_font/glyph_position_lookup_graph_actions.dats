#include "data_font/glyph_position_lookup_graph_internal.hats"
fun push(stack: &GlyphPositionLookupGraphStack >> GlyphPositionLookupGraphStack,depth: int,frame: GlyphPositionLookupGraphFrame,lookup: int,node: int): GlyphPositionLookupGraphEvent =
  if ilt(node,0) then glyph_position_lookup_graph_event_fault(PositionReference()) else let
    val status=glyph_position_lookup_graph_stack_reserve(stack,iadd(depth,2))
  in if not(glyph_position_ready(status)) then glyph_position_lookup_graph_event_fault(status) else let
    val ()=glyph_position_lookup_graph_stack_set(stack,depth,glyph_position_lookup_graph_action(frame))
    val ()=glyph_position_lookup_graph_stack_set(stack,iadd(depth,1),glyph_position_lookup_graph_enter(lookup,node))
  in glyph_position_lookup_graph_event_continue(iadd(depth,1)) end end
implement glyph_position_lookup_graph_actions(b,stack,map,active,used,depth) = let
  val frame=glyph_position_lookup_graph_stack_get(stack,depth)
in if ige(frame.action,frame.context.actionCount) then
  glyph_position_lookup_graph_event_done(stack,active,used,depth,@{status=PositionReady(),next=frame.next,matched=frame.matched}) else let
  val action=ot_context_action(b,frame.context,frame.action)
  val node=glyph_position_lookup_graph_map_node(map,frame.lookup,frame.node,action.position)
in push(stack,depth,frame,action.lookup,node) end end
