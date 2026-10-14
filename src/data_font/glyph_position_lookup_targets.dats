#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_position_lookup_types.sats"
staload "data_font/gpos_mark_matrix.sats"
staload "data_font/gpos_mark_ligature.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run_work.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_pass_work.sats"
staload "data_font/glyph_neighbor_types.sats"
staload "data_font/glyph_neighbor_work.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_pair_work.sats"
staload "data_font/glyph_position_mark_work.sats"
staload "data_font/glyph_position_lookup_work.sats"
implement glyph_position_lookup_mark(b,m,s,meta,f,set,selection,node) = let
  val v=glyph_neighbor_search(b,m,s,meta,glyph_position_mark_flags(f),set,node,GlyphBackward())
in case+ v.status of | NeighborFound() => @{status=PositionReady(),node=if glyph_position_is_mark(m,v.core)
    andalso glyph_pass_selected(selection,v.core.mask) andalso glyph_position_mark_affinity(s,meta,node,v.node) then v.node else ~1}
  | NeighborEnd() => @{status=PositionReady(),node= ~1} | NeighborNode() => @{status=PositionReference(),node= ~1}
  | NeighborDomain() => @{status=PositionDomain(),node= ~1} | NeighborReference() => @{status=PositionReference(),node= ~1} end
