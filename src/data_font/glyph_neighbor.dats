#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_neighbor_types.sats"
staload "data_font/glyph_neighbor_work.sats"
staload "data_font/glyph_neighbor.sats"
implement glyph_neighbor(b,m,run,flags,set,node,travel) = let
  val+ GlyphRun(phase,meta,s)=run
in case+ glyph_neighbor_check(m,meta,flags,set) of
  | NeighborFound() => glyph_neighbor_search(b,m,s,meta,flags,set,node,travel)
  | NeighborDomain() => glyph_neighbor_empty(NeighborDomain())
  | NeighborReference() => glyph_neighbor_empty(NeighborReference())
  | NeighborNode() => glyph_neighbor_empty(NeighborNode())
  | NeighborEnd() => glyph_neighbor_empty(NeighborEnd()) end
