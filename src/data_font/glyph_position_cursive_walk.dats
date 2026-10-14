#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_cursive_types.sats"
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
staload "data_font/glyph_position_anchor.sats"
staload "data_font/glyph_position_cursive_work.sats"
fun candidate{n,m:nat}(b: !Buf,t: !GposCursive,metadata: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,f: OtLookupFlags,set: int,selection: GlyphSelection,d: GlyphPositionDirection,
  c: !GlyphPositionCache(m),node: int,core: GlyphCore): GlyphCursiveStep =
  if not(glyph_position_eligible(b,metadata,f,set,selection,core)) then @{status=PositionReady(),matched=false} else let
    val v=glyph_neighbor_search(b,metadata,s,meta,f,set,node,GlyphBackward())
  in case+ v.status of | NeighborFound() => if glyph_pass_selected(selection,v.core.mask)
    then glyph_position_cursive_step(b,t,s,meta,scale,c,f,d,v.node,node) else @{status=PositionReady(),matched=false}
    | NeighborEnd() => @{status=PositionReady(),matched=false} | NeighborNode() => @{status=PositionReference(),matched=false}
    | NeighborDomain() => @{status=PositionDomain(),matched=false} | NeighborReference() => @{status=PositionReference(),matched=false} end
fun walk{n,m,k:nat} .<k>. (left: int(k),b: !Buf,t: !GposCursive,metadata: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,scale: GlyphScale,f: OtLookupFlags,set: int,selection: GlyphSelection,d: GlyphPositionDirection,
  c: !GlyphPositionCache(m),node: int,matches: &int >> _): GlyphPositionStatus =
  if ieq(node,~1) then PositionReady() else if left = 0 then PositionReference()
  else if not(glyph_run_node(s,meta,node)) then PositionReference() else let
    val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
    val step=candidate(b,t,metadata,s,meta,scale,f,set,selection,d,c,node,core)
    val ()=if step.matched then matches := iadd(matches,1) else ()
  in if not(glyph_position_ready(step.status)) then step.status
    else walk(left-1,b,t,metadata,s,meta,scale,f,set,selection,d,c,links.next,matches) end
implement glyph_position_cursive_walk(b,t,m,s,meta,scale,f,set,selection,d,c,matches) =
  walk(airlock_nat(meta.live),b,t,m,s,meta,scale,f,set,selection,d,c,meta.head,matches)
