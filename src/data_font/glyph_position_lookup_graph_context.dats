#include "data_font/glyph_position_lookup_graph_internal.hats"
fun matched{n:nat}(s: !GlyphStorage(n),w: !GlyphContextWindow,span: GlyphWindowSpan,result: OtContextMatch(2),
  next: int): GlyphPositionLookupGraphStep =
  if not(result.matched) then glyph_position_lookup_graph_completed(@{status=PositionReady(),next=next,matched=false}) else let
    val last=glyph_window_node(w,span,isub(result.inputCount,1))
  in if ilt(last,0) then glyph_position_lookup_graph_failed(PositionReference(),next) else let val links=glyph_storage_links(s,last)
    in @{kind=GraphNested(),status=PositionReady(),next=links.next,matched=true,context=result} end end
fun query{n:nat}(b: !Buf,slot: !OtPositionContext,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  h: OtLookupInfo(2),selection: GlyphSelection,node: int,w: !GlyphContextWindow,remaining: &int >> _): GlyphPositionLookupGraphStep =
  case+ slot of | PositionContextVacant() => glyph_position_lookup_graph_failed(PositionReference(),~1)
  | PositionContext(program,limits) => let
    val links=glyph_storage_links(s,node)
    val options: GlyphWindowSelection= @{flags=h.flags,set=h.markSet,selection=selection}
    val span=glyph_window_gather_limits(b,m,s,meta,options,node,w,limits,remaining)
  in if not(glyph_window_status_valid(span.status)) then
    glyph_position_lookup_graph_failed(glyph_position_lookup_graph_window_status(span.status),links.next)
    else matched(s,w,span,glyph_window_match(b,program,w,span),links.next) end
fun tables{n,k,i:nat | i <= k} .<k-i>. (index: int(i),b: !Buf,t: !OtPositionContexts(k,k),m: !GlyphMetadata,
  s: !GlyphStorage(n),meta: GlyphRunMeta,h: OtLookupInfo(2),selection: GlyphSelection,node: int,
  w: !GlyphContextWindow,remaining: &int >> _): GlyphPositionLookupGraphStep = let
  val+ OtPositionContexts(pf,gc | rows,k,filled)=t val links=glyph_storage_links(s,node)
in if index = k then glyph_position_lookup_graph_completed(@{status=PositionReady(),next=links.next,matched=false})
  else if ile(remaining,0) then glyph_position_lookup_graph_failed(PositionCapacity(),links.next) else let
    val ()=remaining := isub(remaining,1)
    var loan: OtPositionContext=PositionContextVacant()
    val ()=array_exch_at<OtPositionContext>(!rows,i2sz(index),loan)
    val result=query(b,loan,m,s,meta,h,selection,node,w,remaining)
    val ()=array_exch_at<OtPositionContext>(!rows,i2sz(index),loan)
    val ()=ot_position_context_dispose(loan)
  in if result.matched orelse not(glyph_position_ready(result.status)) then result
    else tables(index+1,b,t,m,s,meta,h,selection,node,w,remaining) end end
implement glyph_position_lookup_graph_context(b,entry,m,s,meta,selection,node,w,remaining) = case+ entry of
  | PositionGraphVacant() => glyph_position_lookup_graph_failed(PositionReference(),~1)
  | PositionGraphDirect(t) => glyph_position_lookup_graph_failed(PositionReference(),~1)
  | PositionGraphContext(h,t) => tables(0,b,t,m,s,meta,h,selection,node,w,remaining)
