#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_single_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_single.sats"
fun illegal(b: !Buf,t: !GposSingle,m: !GlyphMetadata,p: GlyphPositioned(1),f: OtLookupFlags): GlyphPositionResult =
  glyph_position_single(b,t,m,p,f,0,@{kind=GlyphAll(),mask=0u})
