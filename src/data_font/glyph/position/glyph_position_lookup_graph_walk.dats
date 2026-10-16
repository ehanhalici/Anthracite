#include "data_font/glyph/position/glyph_position_lookup_graph_internal.hats"
fun walk{n,k,r,f:nat} .<f>. (left: int(f),b: !Buf,g: !OtPositionGraph,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,c: !GlyphPositionCache(k),selection: GlyphSelection,d: GlyphPositionDirection,lookup: int,node: int,
  parents: !GlyphPositionBases(r),w: !GlyphContextWindow,stack: &GlyphPositionLookupGraphStack >> GlyphPositionLookupGraphStack,map: !GlyphPositionLookupGraphMap,
  active: !Buf,remaining: &int >> _,matches: &int >> _): GlyphPositionStatus =
  if ieq(node,~1) then PositionReady() else if left = 0 then PositionReference()
  else if not(glyph_run_node(s,meta,node)) then PositionReference() else let
    val step=glyph_position_lookup_graph_nested(b,g,m,s,meta,scale,c,selection,d,lookup,node,parents,w,stack,map,active,remaining)
    val ()=if step.matched then matches := iadd(matches,1) else ()
  in if not(glyph_position_ready(step.status)) then step.status
    else walk(left-1,b,g,m,s,meta,scale,c,selection,d,lookup,step.next,parents,w,stack,map,active,remaining,matches) end
implement glyph_position_lookup_graph_walk(b,g,m,s,meta,scale,c,selection,d,lookup,parents,w,stack,map,active,remaining,matches) =
  walk(airlock_nat(meta.live),b,g,m,s,meta,scale,c,selection,d,lookup,meta.head,parents,w,stack,map,active,remaining,matches)
