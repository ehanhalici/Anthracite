#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_lookup.sats"
fun illegal(b: !Buf,t: !OtPositionLookup,m: !GlyphMetadata,p: GlyphPositioned(1)): GlyphPositionResult =
  glyph_position_lookup(b,t,m,p,@{kind=GlyphAll(),mask=0u},PositionLTR())
