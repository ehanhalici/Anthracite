#include "share/atspre_staload.hats"
staload "mem.sats"
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
fun illegal{n,m:nat}(b: !Buf,t: !OtPositionTables(2,1),metadata: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,c: !GlyphPositionCache(m),f: OtLookupFlags,set: int,selection: GlyphSelection,d: GlyphPositionDirection,node: int,bases: !GlyphPositionBases(2)): GlyphPairStep =
  glyph_position_lookup_tables(b,t,metadata,s,meta,scale,c,f,set,selection,d,node,bases)
