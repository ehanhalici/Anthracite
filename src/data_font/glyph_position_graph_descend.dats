#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run_work.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_work.sats"
staload "data_font/glyph_position_graph_types.sats"
staload "data_font/glyph_position_graph.sats"
staload "data_font/glyph_position_graph_work.sats"
fun descend{n,m,k,r:nat} .<r>. (left: int(r),s: !GlyphStorage(n),meta: GlyphRunMeta,
  c: !GlyphPositionCache(m),g: !GlyphPositionGraph(k),mode: GlyphPositionGraphMode,node: int,depth: int): GlyphPositionPathStep =
  if ieq(node,~1) then @{status=PositionReady(),node=node,depth=depth}
  else if not(glyph_run_node(s,meta,node)) then @{status=PositionReference(),node=node,depth=depth}
  else case+ glyph_position_graph_visit(g,node) of
    | PositionResolved() => @{status=PositionReady(),node=node,depth=depth}
    | PositionVisiting() => @{status=PositionReference(),node=node,depth=depth}
    | PositionFresh() => if left = 0 then @{status=PositionReference(),node=node,depth=depth} else let
      val ()=glyph_position_graph_push(g,depth,node)
      val ()=glyph_position_graph_set_visit(g,node,PositionVisiting())
      val p=glyph_position_cache_get(c,node)
    in descend(left-1,s,meta,c,g,mode,glyph_position_graph_parent(mode,p),iadd(depth,1)) end
fun unwind{n,m,k:nat} .<k>. (depth: int(k),g: !GlyphPositionGraph(n),c: !GlyphPositionCache(m),mode: GlyphPositionGraphMode): GlyphPositionStatus =
  if depth = 0 then PositionReady() else let
    val node=glyph_position_graph_path(g,depth-1)
    val p=glyph_position_cache_get(c,node) and parent=glyph_position_graph_parent(mode,glyph_position_cache_get(c,node))
    val base=if ieq(parent,~1) then glyph_position_empty() else glyph_position_cache_get(c,parent)
    val change=glyph_position_graph_change(g,mode,node,p,base)
  in if not(glyph_position_ready(change.status)) then change.status else let
    val ()=glyph_position_cache_set(c,node,change.value)
    val ()=glyph_position_graph_set_visit(g,node,PositionResolved())
  in unwind(depth-1,g,c,mode) end end
implement glyph_position_graph_chain(s,meta,c,g,mode,node) = let
  val path=descend(airlock_nat(meta.live),s,meta,c,g,mode,node,0)
in if glyph_position_ready(path.status) then unwind(airlock_nat(path.depth),g,c,mode) else path.status end
