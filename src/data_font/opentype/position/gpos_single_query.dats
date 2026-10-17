#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
staload "data_font/opentype/position/gpos_values.sats"
staload "data_font/opentype/tables/opentype_coverage.sats"
staload "data_font/opentype/position/gpos_value_cache.sats"
staload "data_font/opentype/position/gpos_value_cache_types.sats"
staload "data_font/opentype/position/gpos_single_types.sats"
staload "data_font/opentype/position/gpos_single.sats"
implement gpos_single_query(b,table,glyph) = let val+ GposSingle(info,cache)=table in
  let val c=ot_coverage_index(b,info.coverage,glyph)
  in if not(c.found) then @{matched=false,value=ot_value_zero()} else let
    val index=case+ info.encoding of | PositionUniform() => 0 | PositionIndexed() => c.index
  in @{matched=true,value=ot_value_cache_get(cache,index)} end end end
implement gpos_single_dispose(table) = let val+ ~GposSingle(info,cache)=table in ot_value_cache_dispose(cache) end
implement gpos_single_glyphs(table) = let val+ GposSingle(info,cache)=table in info.glyphs end
