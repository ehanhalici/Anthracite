#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/definition/gdef_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata_work.sats"
implement glyph_property_rows_make(count) = let
  val empty: GlyphProperty= @{kind=GlyphUnclassified(),attachment=0}
  val rows=arrayptr_make_elt<GlyphProperty>(g1int2uint_int_size(count),empty)
in GlyphPropertyRows(rows,count,0) end
implement glyph_property_rows_append(cache,property) = let
  val+ ~GlyphPropertyRows(rows,count,filled)=cache
  val ()=arrayptr_set_at<GlyphProperty>(rows,g1int2uint_int_size(filled),property)
in GlyphPropertyRows(rows,count,filled+1) end
implement glyph_property_rows_get(cache,index) = let val+ GlyphPropertyRows(rows,count,filled)=cache in
  arrayptr_get_at<GlyphProperty>(rows,g1int2uint_int_size(airlock_below(index,count))) end
implement glyph_property_rows_dispose(cache) = let val+ ~GlyphPropertyRows(rows,count,filled)=cache in
  arrayptr_free(rows) end
