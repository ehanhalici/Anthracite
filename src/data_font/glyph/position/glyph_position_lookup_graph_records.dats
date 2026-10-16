#include "data_font/glyph/position/glyph_position_lookup_graph_internal.hats"
fun no_context(): OtContextMatch(2) = @{domain=OtPositioning(),matched=false,inputCount=0,
  actions= @{offset=0,length=0},actionCount=0,rule=0}
implement glyph_position_lookup_graph_enter(lookup,node) = @{state=GraphEnter(),lookup=lookup,node=node,action=0,
  next= ~1,matched=false,context=no_context()}
implement glyph_position_lookup_graph_empty() = glyph_position_lookup_graph_enter(~1,~1)
implement glyph_position_lookup_graph_frame(old,step) = @{state=GraphActions(),lookup=old.lookup,node=old.node,action=0,
  next=step.next,matched=step.matched,context=step.context}
implement glyph_position_lookup_graph_action(old) = @{state=old.state,lookup=old.lookup,node=old.node,action=iadd(old.action,1),
  next=old.next,matched=old.matched,context=old.context}
implement glyph_position_lookup_graph_completed(r) = @{kind=GraphCompleted(),status=r.status,next=r.next,matched=r.matched,
  context=no_context()}
implement glyph_position_lookup_graph_failed(status,next) = glyph_position_lookup_graph_completed(@{status=status,next=next,matched=false})
implement glyph_position_lookup_graph_window_status(status) = case+ status of | WindowReady() => PositionReady()
  | WindowSkipped() => PositionReady() | WindowDomain() => PositionDomain()
  | WindowReference() => PositionReference() | WindowCapacity() => PositionCapacity()
