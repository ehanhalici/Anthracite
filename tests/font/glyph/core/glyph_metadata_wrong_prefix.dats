#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/definition/gdef_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata_work.sats"
extern fun unfinished_property(t: !GlyphPropertyRows(2,1)): GlyphProperty
implement unfinished_property(t) = glyph_property_rows_get(t,0)
