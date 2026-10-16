#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_work.sats"
staload "data_font/glyph/position/glyph_position_graph_types.sats"
staload "data_font/glyph/position/glyph_position_graph.sats"
staload "data_font/glyph/position/glyph_position_graph_work.sats"
fun walk{n,m,k,r:nat} .<r>. (left: int(r),s: !GlyphStorage(n),meta: GlyphRunMeta,
  c: !GlyphPositionCache(m),g: !GlyphPositionGraph(k),mode: GlyphPositionGraphMode,node: int): GlyphPositionStatus =
  if left = 0 then PositionReady() else let
    val status=glyph_position_graph_chain(s,meta,c,g,mode,node)
    val links=glyph_storage_links(s,node)
  in if glyph_position_ready(status) then walk(left-1,s,meta,c,g,mode,links.next) else status end
implement glyph_position_graph_resolve(s,meta,c,g,mode) = walk(airlock_nat(meta.live),s,meta,c,g,mode,meta.head)
