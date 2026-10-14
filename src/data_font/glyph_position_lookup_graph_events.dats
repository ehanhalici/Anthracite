#include "data_font/glyph_position_lookup_graph_internal.hats"
implement glyph_position_lookup_graph_event_fault(status) = @{kind=GraphFault(),depth=0,result= @{status=status,next= ~1,matched=false}}
implement glyph_position_lookup_graph_event_continue(depth) =
  @{kind=GraphContinue(),depth=depth,result= @{status=PositionReady(),next= ~1,matched=false}}
implement glyph_position_lookup_graph_event_done(stack,active,used,depth,result) = let
  val frame=glyph_position_lookup_graph_stack_get(stack,depth)
  val ()=buf_set32(active,iadd(imul(frame.lookup,used),frame.node),0)
in if ieq(depth,0) then @{kind=GraphReturned(),depth=0,result=result}
  else glyph_position_lookup_graph_event_continue(isub(depth,1)) end
