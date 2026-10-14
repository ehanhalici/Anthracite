#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_position_lookup_types.sats"
staload "data_font/gpos_single_types.sats"
staload "data_font/gpos_single.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_work.sats"
staload "data_font/glyph_position_pair_work.sats"
staload "data_font/glyph_position_mark_work.sats"
staload "data_font/glyph_position_lookup_work.sats"
implement glyph_position_lookup_single(b,t,scale,c,node,core,next) = let val query=gpos_single_query(b,t,core.glyph) in
  if not(query.matched) then @{status=PositionReady(),next=next,matched=false} else let
    val change=glyph_position_value(b,scale,query.value,glyph_position_cache_get(c,node))
    val ()=if glyph_position_ready(change.status) then glyph_position_cache_set(c,node,change.value) else ()
  in @{status=change.status,next=next,matched=true} end end
