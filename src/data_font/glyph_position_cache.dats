#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position.sats"
staload "data_font/glyph_position_work.sats"
implement glyph_position_cache_make(count) = let
  val rows=arrayptr_make_elt<GlyphPosition>(g1int2uint_int_size(count),glyph_position_empty())
in GlyphPositionCache(rows,count) end
implement glyph_position_cache_get(cache,index) = let val+ GlyphPositionCache(rows,count)=cache in
  arrayptr_get_at<GlyphPosition>(rows,g1int2uint_int_size(airlock_below(index,count))) end
implement glyph_position_cache_set(cache,index,value) = let val+ GlyphPositionCache(rows,count)=cache in
  arrayptr_set_at<GlyphPosition>(rows,g1int2uint_int_size(airlock_below(index,count)),value) end
implement glyph_position_cache_dispose(cache) = let val+ ~GlyphPositionCache(rows,count)=cache in arrayptr_free(rows) end
