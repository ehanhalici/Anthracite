#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_mark_matrix_types.sats"
staload "data_font/gpos_mark_matrix.sats"
staload "data_font/gpos_mark_ligature_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_pass_work.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run_work.sats"
staload "data_font/glyph_neighbor_types.sats"
staload "data_font/glyph_neighbor_work.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_work.sats"
staload "data_font/glyph_position_filter.sats"
staload "data_font/glyph_position_mark_work.sats"
fun parent{n,kind:int | n >= 0}(b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  domain: GposMarkMatrixDomain(kind),f: OtLookupFlags,set: int,selection: GlyphSelection,node: int,base: int): GlyphMarkParent = case+ domain of
  | MarkToBase() => @{status=PositionReady(),node=base}
  | MarkToMark() => let val v=glyph_neighbor_search(b,m,s,meta,glyph_position_mark_flags(f),set,node,GlyphBackward())
    in case+ v.status of | NeighborFound() => @{status=PositionReady(),node=if glyph_position_is_mark(m,v.core)
      andalso glyph_pass_selected(selection,v.core.mask) andalso glyph_position_mark_affinity(s,meta,node,v.node) then v.node else ~1}
      | NeighborEnd() => @{status=PositionReady(),node= ~1}
      | NeighborNode() => @{status=PositionReference(),node= ~1}
      | NeighborDomain() => @{status=PositionDomain(),node= ~1}
      | NeighborReference() => @{status=PositionReference(),node= ~1} end
fun candidate{n,m,kind:int | n >= 0; m >= 0}(b: !Buf,t: !GposMarkMatrix(kind),metadata: !GlyphMetadata,
  s: !GlyphStorage(n),meta: GlyphRunMeta,scale: GlyphScale,f: OtLookupFlags,set: int,selection: GlyphSelection,
  c: !GlyphPositionCache(m),domain: GposMarkMatrixDomain(kind),node: int,base: int,core: GlyphCore): GlyphMarkStep =
  if glyph_position_eligible(b,metadata,f,set,selection,core)
  then let val p=parent(b,metadata,s,meta,domain,f,set,selection,node,base) in
    if glyph_position_ready(p.status) then glyph_position_mark_matrix_step(b,t,metadata,s,meta,scale,c,node,p.node)
    else @{status=p.status,matched=false} end
  else @{status=PositionReady(),matched=false}
fun next_base{n,kind:int | n >= 0}(b: !Buf,t: !GposMarkMatrix(kind),metadata: !GlyphMetadata,s: !GlyphStorage(n),
  selection: GlyphSelection,node: int,base: int,core: GlyphCore,previous: int): int =
  if glyph_position_is_mark(metadata,core) then base
  else if not(glyph_pass_selected(selection,core.mask)) then base
  else if glyph_position_mark_base_accept(metadata,s,core,previous) orelse gpos_mark_matrix_target(b,t,core.glyph) then node
  else base
fun walk{n,m,kind:int | n >= 0; m >= 0}{k:nat} .<k>. (left: int(k),b: !Buf,t: !GposMarkMatrix(kind),
  metadata: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,scale: GlyphScale,f: OtLookupFlags,set: int,
  selection: GlyphSelection,c: !GlyphPositionCache(m),domain: GposMarkMatrixDomain(kind),node: int,base: int,matches: &int >> _): GlyphPositionStatus =
  if ieq(node,~1) then PositionReady()
  else if left = 0 then PositionReference()
  else if not(glyph_run_node(s,meta,node)) then PositionReference() else let
    val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
    val step=candidate(b,t,metadata,s,meta,scale,f,set,selection,c,domain,node,base,core)
    val ()=if step.matched then matches := iadd(matches,1) else ()
    val next=next_base(b,t,metadata,s,selection,node,base,core,links.previous)
  in if not(glyph_position_ready(step.status)) then step.status
    else walk(left-1,b,t,metadata,s,meta,scale,f,set,selection,c,domain,links.next,next,matches) end
implement glyph_position_mark_matrix_walk(b,t,m,s,meta,scale,f,set,selection,c,matches) = let
  val+ GposMarkMatrix(domain,info,a,d)=t
in walk(airlock_nat(meta.live),b,t,m,s,meta,scale,f,set,selection,c,domain,meta.head,~1,matches) end
