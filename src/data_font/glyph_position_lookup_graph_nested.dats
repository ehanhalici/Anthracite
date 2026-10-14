#include "data_font/glyph_position_lookup_graph_internal.hats"
extern fun position_graph_fuel_failed(): int = "mac#anth_die_int"
fun walk{n,k,r,f:nat} .<f>. (left: int(f),b: !Buf,g: !OtPositionGraph,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,c: !GlyphPositionCache(k),selection: GlyphSelection,d: GlyphPositionDirection,
  parents: !GlyphPositionBases(r),w: !GlyphContextWindow,stack: &GlyphPositionLookupGraphStack >> GlyphPositionLookupGraphStack,map: !GlyphPositionLookupGraphMap,
  active: !Buf,depth: int,remaining: &int >> _): GlyphPairStep =
  if ile(remaining,0) then @{status=PositionCapacity(),next= ~1,matched=false}
  else if left = 0 then let val failed=position_graph_fuel_failed() in @{status=PositionReference(),next=failed,matched=false} end else let
    val ()=remaining := isub(remaining,1)
    val event=glyph_position_lookup_graph_transition(b,g,m,s,meta,scale,c,selection,d,parents,w,stack,map,active,depth,remaining)
  in case+ event.kind of | GraphReturned() => event.result | GraphFault() => event.result
    | GraphContinue() => walk(left-1,b,g,m,s,meta,scale,c,selection,d,parents,w,stack,map,active,event.depth,remaining) end
implement glyph_position_lookup_graph_nested(b,g,m,s,meta,scale,c,selection,d,lookup,node,parents,w,stack,map,active,remaining) = let
  val ()=glyph_position_lookup_graph_stack_set(stack,0,glyph_position_lookup_graph_enter(lookup,node))
in walk(MAX_REC_FUEL,b,g,m,s,meta,scale,c,selection,d,parents,w,stack,map,active,0,remaining) end
