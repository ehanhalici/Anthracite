#include "data_font/glyph/position/glyph_position_lookup_graph_internal.hats"
extern fun graph_map_header_failed(): int = "mac#anth_die_int"
fun header(entry: !OtPositionGraphEntry): OtLookupInfo(2) = case+ entry of
  | PositionGraphDirect(t) => let val+ OtPositionLookup(h,a,glyphs,tables)=t in h end
  | PositionGraphContext(h,t) => h | PositionGraphVacant() => let val failed=graph_map_header_failed()
    in @{span= @{offset=failed,length=0},action=PosSingle(),flags= @{rtl=false,ignoreBase=false,ignoreLigature=false,
      ignoreMarks=false,useMarkSet=false,attachment=0},count=0,markSet=0} end
fun walk{n,k:nat} .<k>. (left: int(k),b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,h: OtLookupInfo(2),
  nodes: !Buf,ranks: !Buf,offset: int,node: int,rank: &int >> _): GlyphPositionStatus =
  if ieq(node,~1) then PositionReady() else if left = 0 then PositionReference()
  else if not(glyph_run_node(s,meta,node)) then PositionReference() else let
    val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
    val keep=glyph_metadata_allows_core(b,m,h.flags,h.markSet,core)
    val ()=buf_set32(ranks,iadd(offset,node),if keep then rank else ~1)
    val ()=if keep then let val ()=buf_set32(nodes,iadd(offset,rank),node) in rank := iadd(rank,1) end else ()
  in walk(left-1,b,m,s,meta,h,nodes,ranks,offset,links.next,rank) end
fun tables{n,k,i:nat | i <= k} .<k-i>. (index: int(i),b: !Buf,t: !OtPositionGraphEntries(k,k),m: !GlyphMetadata,
  s: !GlyphStorage(n),meta: GlyphRunMeta,map: !GlyphPositionLookupGraphMap): GlyphPositionStatus = let
  val+ OtPositionGraphEntries(pf,gc | rows,k,filled)=t val+ GlyphPositionLookupGraphMap(nodes,ranks,counts,lookups,used)=map
in if index = k then PositionReady() else let
  var loan: OtPositionGraphEntry=PositionGraphVacant()
  val ()=array_exch_at<OtPositionGraphEntry>(!rows,i2sz(index),loan)
  val h=header(loan)
  val ()=array_exch_at<OtPositionGraphEntry>(!rows,i2sz(index),loan)
  val ()=ot_position_graph_entry_dispose(loan)
  var rank: int=0
  val status=walk(airlock_nat(meta.live),b,m,s,meta,h,nodes,ranks,imul(index,used),meta.head,rank)
  val ()=buf_set32(counts,index,rank)
in if glyph_position_ready(status) then tables(index+1,b,t,m,s,meta,map) else status end end
implement glyph_position_lookup_graph_map_build(b,g,m,s,meta,map) = let val+ OtPositionGraph(font,glyphs,limits,t)=g
in tables(0,b,t,m,s,meta,map) end
