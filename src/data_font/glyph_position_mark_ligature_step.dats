#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/gpos_mark_matrix_types.sats"
staload "data_font/gpos_mark_ligature_types.sats"
staload "data_font/gpos_mark_ligature.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_anchor.sats"
staload "data_font/glyph_position_mark_work.sats"
implement glyph_position_mark_ligature_step(b,t,s,meta,scale,c,node,parent) =
  if ieq(parent,~1) then @{status=PositionReady(),matched=false} else let
    val core=glyph_storage_core(s,node) and base=glyph_storage_core(s,parent)
    val count=gpos_mark_ligature_components(b,t,base.glyph)
    val component=glyph_position_mark_component(s,meta,node,parent,count)
    val query=gpos_mark_ligature_query(b,t,core.glyph,base.glyph,component)
  in if not(query.matched) then @{status=PositionReady(),matched=false} else let
    val cross=glyph_position_mark_cross(s,meta,c,parent)
    val status=glyph_position_anchor_attach(b,scale,c,cross,node,parent,query.mark,query.target)
  in @{status=status,matched=true} end end
