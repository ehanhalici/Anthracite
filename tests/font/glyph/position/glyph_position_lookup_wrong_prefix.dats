#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_pair_work.sats"
staload "data_font/glyph/position/glyph_position_mark_work.sats"
staload "data_font/glyph/position/glyph_position_lookup_work.sats"
fun illegal{n,m:nat}(b: !Buf,t: !OtPositionTables(2,1),metadata: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,c: !GlyphPositionCache(m),f: OtLookupFlags,set: int,selection: GlyphSelection,d: GlyphPositionDirection,node: int,bases: !GlyphPositionBases(2)): GlyphPairStep =
  glyph_position_lookup_tables(b,t,metadata,s,meta,scale,c,f,set,selection,d,node,bases)
