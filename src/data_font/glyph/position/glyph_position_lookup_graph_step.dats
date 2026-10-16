#include "data_font/glyph/position/glyph_position_lookup_graph_internal.hats"
fun entry{n,k,r:nat}(b: !Buf,e: !OtPositionGraphEntry,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,c: !GlyphPositionCache(k),selection: GlyphSelection,d: GlyphPositionDirection,node: int,
  parents: !GlyphPositionBases(r),w: !GlyphContextWindow,remaining: &int >> _): GlyphPositionLookupGraphStep = case+ e of
  | PositionGraphVacant() => glyph_position_lookup_graph_failed(PositionReference(),~1)
  | PositionGraphDirect(t) => glyph_position_lookup_graph_completed(glyph_position_lookup_graph_direct(b,t,m,s,meta,scale,c,selection,d,node,parents,remaining))
  | PositionGraphContext(h,t) => glyph_position_lookup_graph_context(b,e,m,s,meta,selection,node,w,remaining)
implement glyph_position_lookup_graph_step(b,g,m,s,meta,scale,c,selection,d,lookup,node,parents,w,remaining) = let
  val+ OtPositionGraph(font,glyphs,limits,entries)=g val+ OtPositionGraphEntries(pf,gc | rows,count,filled)=entries
in if ilt(lookup,0) orelse ige(lookup,count) orelse not(glyph_run_node(s,meta,node))
  then glyph_position_lookup_graph_failed(PositionReference(),~1)
  else if ile(remaining,0) then glyph_position_lookup_graph_failed(PositionCapacity(),~1) else let
    val ()=remaining := isub(remaining,1)
    var loan: OtPositionGraphEntry=PositionGraphVacant()
    val ()=array_exch_at<OtPositionGraphEntry>(!rows,i2sz(airlock_below(lookup,count)),loan)
    val result=entry(b,loan,m,s,meta,scale,c,selection,d,node,parents,w,remaining)
    val ()=array_exch_at<OtPositionGraphEntry>(!rows,i2sz(airlock_below(lookup,count)),loan)
    val ()=ot_position_graph_entry_dispose(loan)
  in result end end
