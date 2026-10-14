#include "data_font/glyph_position_lookup_graph_internal.hats"
fun dispatched(stack: &GlyphPositionLookupGraphStack >> GlyphPositionLookupGraphStack,active: !Buf,used: int,depth: int,
  frame: GlyphPositionLookupGraphFrame,step: GlyphPositionLookupGraphStep): GlyphPositionLookupGraphEvent =
  if not(glyph_position_ready(step.status)) then glyph_position_lookup_graph_event_fault(step.status) else case+ step.kind of
    | GraphCompleted() => glyph_position_lookup_graph_event_done(stack,active,used,depth,@{status=step.status,next=step.next,matched=step.matched})
    | GraphNested() => let val ()=glyph_position_lookup_graph_stack_set(stack,depth,glyph_position_lookup_graph_frame(frame,step))
      in glyph_position_lookup_graph_event_continue(depth) end
fun entered{n,k,r:nat}(b: !Buf,g: !OtPositionGraph,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,c: !GlyphPositionCache(k),selection: GlyphSelection,d: GlyphPositionDirection,
  parents: !GlyphPositionBases(r),w: !GlyphContextWindow,stack: &GlyphPositionLookupGraphStack >> GlyphPositionLookupGraphStack,active: !Buf,
  depth: int,frame: GlyphPositionLookupGraphFrame,remaining: &int >> _): GlyphPositionLookupGraphEvent = let
  val+ OtPositionGraph(font,glyphs,limits,t)=g val+ OtPositionGraphEntries(pf,gc | rows,count,filled)=t
in if ilt(frame.lookup,0) orelse ige(frame.lookup,count) orelse not(glyph_run_node(s,meta,frame.node))
  then glyph_position_lookup_graph_event_fault(PositionReference()) else let val at=iadd(imul(frame.lookup,meta.used),frame.node)
  in if ine(buf_get32(active,at),0) then glyph_position_lookup_graph_event_fault(PositionReference()) else let
    val ()=buf_set32(active,at,1)
    val step=glyph_position_lookup_graph_step(b,g,m,s,meta,scale,c,selection,d,frame.lookup,frame.node,parents,w,remaining)
  in dispatched(stack,active,meta.used,depth,frame,step) end end end
implement glyph_position_lookup_graph_transition(b,g,m,s,meta,scale,c,selection,d,parents,w,stack,map,active,depth,remaining) = let
  val frame=glyph_position_lookup_graph_stack_get(stack,depth)
in case+ frame.state of
  | GraphEnter() => entered(b,g,m,s,meta,scale,c,selection,d,parents,w,stack,active,depth,frame,remaining)
  | GraphActions() => glyph_position_lookup_graph_actions(b,stack,map,active,meta.used,depth) end
