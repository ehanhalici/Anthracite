#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_position_lookup_types.sats"
staload "data_font/gpos_cursive_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_pass_work.sats"
staload "data_font/glyph_neighbor_types.sats"
staload "data_font/glyph_neighbor_work.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_anchor.sats"
staload "data_font/glyph_position_cursive_work.sats"
staload "data_font/glyph_position_pair_work.sats"
staload "data_font/glyph_position_mark_work.sats"
staload "data_font/glyph_position_lookup_work.sats"
fun neighbor_status(status: GlyphNeighborStatus): GlyphPositionStatus = case+ status of
  | NeighborFound() => PositionReady() | NeighborEnd() => PositionReady()
  | NeighborDomain() => PositionDomain() | NeighborReference() => PositionReference() | NeighborNode() => PositionReference()
implement glyph_position_lookup_pair(b,t,m,s,meta,scale,c,f,set,selection,node,core,next) = let
  val v=glyph_neighbor_search(b,m,s,meta,f,set,node,GlyphForward())
in case+ v.status of | NeighborFound() => if glyph_pass_selected(selection,v.core.mask)
    then glyph_position_pair_apply(b,t,s,scale,c,node,v.node,core) else @{status=PositionReady(),next=next,matched=false}
  | NeighborEnd() => @{status=PositionReady(),next=next,matched=false}
  | NeighborDomain() => @{status=PositionDomain(),next=next,matched=false}
  | NeighborReference() => @{status=PositionReference(),next=next,matched=false}
  | NeighborNode() => @{status=PositionReference(),next=next,matched=false} end
implement glyph_position_lookup_cursive(b,t,m,s,meta,scale,c,f,set,selection,d,node,next) = let
  val v=glyph_neighbor_search(b,m,s,meta,f,set,node,GlyphBackward())
in case+ v.status of | NeighborFound() => if glyph_pass_selected(selection,v.core.mask) then let
    val a=glyph_position_cursive_step(b,t,s,meta,scale,c,f,d,v.node,node)
  in @{status=a.status,next=next,matched=a.matched} end else @{status=PositionReady(),next=next,matched=false}
  | NeighborEnd() => @{status=PositionReady(),next=next,matched=false}
  | NeighborDomain() => @{status=PositionDomain(),next=next,matched=false}
  | NeighborReference() => @{status=PositionReference(),next=next,matched=false}
  | NeighborNode() => @{status=PositionReference(),next=next,matched=false} end
