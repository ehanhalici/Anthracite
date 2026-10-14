#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_position_lookup_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_pair_work.sats"
staload "data_font/glyph_position_mark_work.sats"
staload "data_font/glyph_position_lookup_work.sats"
implement glyph_position_bases_make(n) = GlyphPositionBases(arrayptr_make_elt<int>(i2sz(n),~1),n)
implement glyph_position_bases_get(b,i) = let val+ GlyphPositionBases(rows,n)=b
  val index=airlock_below(i,n) in arrayptr_get_at<int>(rows,i2sz(index)) end
implement glyph_position_bases_set(b,i,node) = let val+ GlyphPositionBases(rows,n)=b
  val index=airlock_below(i,n) in arrayptr_set_at<int>(rows,i2sz(index),node) end
implement glyph_position_bases_dispose(b) = let val+ ~GlyphPositionBases(rows,n)=b in arrayptr_free(rows) end
