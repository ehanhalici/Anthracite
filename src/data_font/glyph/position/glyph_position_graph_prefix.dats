#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run_work.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_work.sats"
staload "data_font/glyph/position/glyph_position_graph_types.sats"
staload "data_font/glyph/position/glyph_position_graph.sats"
extern fun prefix_graph_failed(): int = "mac#anth_die_int"
fun walk{n,m,k,r:nat} .<r>. (left: int(r),s: !GlyphStorage(n),meta: GlyphRunMeta,
  cache: !GlyphPositionCache(m),g: !GlyphPositionGraph(k),d: GlyphPositionDirection,node: int,
  pen: GlyphPositionOrigin): GlyphPositionStatus =
  if ieq(node,~1) then PositionReady()
  else if left = 0 then let val failed=prefix_graph_failed() in PositionReference() end
  else if not(glyph_run_node(s,meta,node)) then PositionReference() else let
    val p=glyph_position_cache_get(cache,node)
    val next: GlyphPositionOrigin= @{x=pen.x+g0int2int_int_llint(p.xAdvance),y=pen.y+g0int2int_int_llint(p.yAdvance)}
    val origin=case+ d of | PositionLTR() => pen | PositionRTL() => next
    val ()=glyph_position_graph_set_origin(g,node,origin)
    val links=glyph_storage_links(s,node)
  in walk(left-1,s,meta,cache,g,d,links.next,next) end
implement glyph_position_graph_prefix(s,meta,c,g,d) = walk(airlock_nat(meta.live),s,meta,c,g,d,meta.head,@{x=0LL,y=0LL})
