#include "data_font/glyph_position_lookup_graph_internal.hats"
fun payload{n,k,r:nat}(b: !Buf,p: !OtPositionPayload,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,c: !GlyphPositionCache(k),h: OtLookupInfo(2),selection: GlyphSelection,d: GlyphPositionDirection,
  node: int,parents: !GlyphPositionBases(r),remaining: &int >> _): GlyphPairStep = let
  val parent=glyph_position_lookup_graph_parent(b,p,m,s,meta,node,parents,remaining)
  val links=glyph_storage_links(s,node)
in if not(glyph_position_ready(parent.status)) then @{status=parent.status,next=links.next,matched=false}
  else glyph_position_lookup_payload(b,p,m,s,meta,scale,c,h.flags,h.markSet,selection,d,node,parent.node) end
fun tables{n,k,r,z,i:nat | i <= z} .<z-i>. (index: int(i),b: !Buf,t: !OtPositionTables(z,z),m: !GlyphMetadata,
  s: !GlyphStorage(n),meta: GlyphRunMeta,scale: GlyphScale,c: !GlyphPositionCache(k),h: OtLookupInfo(2),
  selection: GlyphSelection,d: GlyphPositionDirection,node: int,parents: !GlyphPositionBases(r),remaining: &int >> _): GlyphPairStep = let
  val+ OtPositionTables(pf,gc | rows,z,filled)=t val links=glyph_storage_links(s,node)
in if index = z then @{status=PositionReady(),next=links.next,matched=false}
  else if ile(remaining,0) then @{status=PositionCapacity(),next=links.next,matched=false} else let
    val ()=remaining := isub(remaining,1)
    var loan: OtPositionPayload=PositionPayloadVacant()
    val ()=array_exch_at<OtPositionPayload>(!rows,i2sz(index),loan)
    val result=payload(b,loan,m,s,meta,scale,c,h,selection,d,node,parents,remaining)
    val ()=array_exch_at<OtPositionPayload>(!rows,i2sz(index),loan)
    val ()=ot_position_payload_dispose(loan)
  in if result.matched orelse not(glyph_position_ready(result.status)) then result
    else tables(index+1,b,t,m,s,meta,scale,c,h,selection,d,node,parents,remaining) end end
implement glyph_position_lookup_graph_direct(b,t,m,s,meta,scale,c,selection,d,node,parents,remaining) = let
  val+ OtPositionLookup(h,a,glyphs,tables0)=t
  val links=glyph_storage_links(s,node) and core=glyph_storage_core(s,node)
in if not(glyph_position_eligible(b,m,h.flags,h.markSet,selection,core))
  then @{status=PositionReady(),next=links.next,matched=false}
  else tables(0,b,tables0,m,s,meta,scale,c,h,selection,d,node,parents,remaining) end
