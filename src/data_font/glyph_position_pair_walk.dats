#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_pair_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run_work.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_pass_work.sats"
staload "data_font/glyph_neighbor_types.sats"
staload "data_font/glyph_neighbor_work.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_work.sats"
staload "data_font/glyph_position_filter.sats"
staload "data_font/glyph_position_pair_work.sats"
extern fun pair_position_graph_failed(): int = "mac#anth_die_int"
fun chosen{n,m:nat}(b: !Buf,t: !GposPairs,metadata: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,f: OtLookupFlags,set: int,selection: GlyphSelection,cache: !GlyphPositionCache(m),node: int,
  core: GlyphCore,next: int): GlyphPairStep = let val neighbor=glyph_neighbor_search(b,metadata,s,meta,f,set,node,GlyphForward())
in case+ neighbor.status of
  | NeighborFound() => if glyph_pass_selected(selection,neighbor.core.mask)
    then glyph_position_pair_apply(b,t,s,scale,cache,node,neighbor.node,core)
    else @{status=PositionReady(),next=next,matched=false}
  | NeighborEnd() => @{status=PositionReady(),next=next,matched=false}
  | NeighborDomain() => @{status=PositionDomain(),next=next,matched=false}
  | NeighborReference() => @{status=PositionReference(),next=next,matched=false}
  | NeighborNode() => let val failed=pair_position_graph_failed() in @{status=PositionReference(),next=failed,matched=false} end end
fun candidate{n,m:nat}(b: !Buf,t: !GposPairs,metadata: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,f: OtLookupFlags,set: int,selection: GlyphSelection,cache: !GlyphPositionCache(m),node: int,
  core: GlyphCore,next: int): GlyphPairStep =
  if glyph_position_eligible(b,metadata,f,set,selection,core)
  then chosen(b,t,metadata,s,meta,scale,f,set,selection,cache,node,core,next)
  else @{status=PositionReady(),next=next,matched=false}
fun walk{n,m,k:nat} .<k>. (left: int(k),b: !Buf,t: !GposPairs,metadata: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,scale: GlyphScale,f: OtLookupFlags,set: int,selection: GlyphSelection,
  cache: !GlyphPositionCache(m),node: int,matches: &int >> _): GlyphPositionStatus =
  if ieq(node,~1) then PositionReady()
  else if left = 0 then let val failed=pair_position_graph_failed() in PositionReference() end
  else if not(glyph_run_node(s,meta,node)) then let val failed=pair_position_graph_failed() in PositionReference() end else let
    val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
    val result: GlyphPairStep=candidate(b,t,metadata,s,meta,scale,f,set,selection,cache,node,core,links.next)
    val @{status=status,next=next,matched=matched}=result
    val ()=if matched then matches := iadd(matches,1) else ()
  in if not(glyph_position_ready(status)) then status
    else walk(left-1,b,t,metadata,s,meta,scale,f,set,selection,cache,next,matches) end
implement glyph_position_pair_walk(b,t,m,s,meta,scale,f,set,selection,cache,matches) =
  walk(airlock_nat(meta.live),b,t,m,s,meta,scale,f,set,selection,cache,meta.head,matches)
