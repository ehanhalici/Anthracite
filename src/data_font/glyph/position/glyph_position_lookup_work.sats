staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_types.sats"
staload "data_font/opentype/position/gpos_single_types.sats"
staload "data_font/opentype/position/gpos_pair_types.sats"
staload "data_font/opentype/position/gpos_cursive_types.sats"
staload "data_font/opentype/position/gpos_mark_matrix_types.sats"
staload "data_font/opentype/position/gpos_mark_ligature_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_pair_work.sats"
staload "data_font/glyph/position/glyph_position_mark_work.sats"
fun glyph_position_lookup_check(t: !OtPositionLookup,m: !GlyphMetadata,meta: GlyphRunMeta): GlyphPositionStatus
fun glyph_position_lookup_single{n:nat}(b: !Buf,t: !GposSingle,scale: GlyphScale,c: !GlyphPositionCache(n),
  node: int,core: GlyphCore,next: int): GlyphPairStep
fun glyph_position_lookup_pair{n,m:nat}(b: !Buf,t: !GposPairs,metadata: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,c: !GlyphPositionCache(m),f: OtLookupFlags,set: int,selection: GlyphSelection,node: int,core: GlyphCore,next: int): GlyphPairStep
fun glyph_position_lookup_cursive{n,m:nat}(b: !Buf,t: !GposCursive,metadata: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,c: !GlyphPositionCache(m),f: OtLookupFlags,set: int,selection: GlyphSelection,d: GlyphPositionDirection,node: int,next: int): GlyphPairStep
fun glyph_position_lookup_mark{n:nat}(b: !Buf,metadata: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  f: OtLookupFlags,set: int,selection: GlyphSelection,node: int): GlyphMarkParent
fun glyph_position_lookup_payload{n,m:nat}(b: !Buf,p: !OtPositionPayload,metadata: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,c: !GlyphPositionCache(m),f: OtLookupFlags,set: int,selection: GlyphSelection,d: GlyphPositionDirection,node: int,base: int): GlyphPairStep
datavtype GlyphPositionBases(int) = {n:nat}{l:addr} GlyphPositionBases(n) of (arrayptr(int,l,n),int(n))
fun glyph_position_bases_make{n:nat}(n: int(n)): GlyphPositionBases(n)
fun glyph_position_bases_get{n:nat}(bases: !GlyphPositionBases(n),i: int): int
fun glyph_position_bases_set{n:nat}(bases: !GlyphPositionBases(n),i: int,node: int): void
fun glyph_position_bases_dispose{n:nat}(bases: GlyphPositionBases(n)): void
fun glyph_position_lookup_tables{n,m,k:nat}(b: !Buf,t: !OtPositionTables(k,k),metadata: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,c: !GlyphPositionCache(m),f: OtLookupFlags,set: int,selection: GlyphSelection,d: GlyphPositionDirection,node: int,bases: !GlyphPositionBases(k)): GlyphPairStep
fun glyph_position_lookup_refresh{n,k:nat}(b: !Buf,t: !OtPositionTables(k,k),metadata: !GlyphMetadata,s: !GlyphStorage(n),node: int,
  selection: GlyphSelection,bases: !GlyphPositionBases(k)): void
fun glyph_position_lookup_walk{n,m:nat}(b: !Buf,t: !OtPositionLookup,metadata: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,c: !GlyphPositionCache(m),selection: GlyphSelection,d: GlyphPositionDirection,matches: &int >> _): GlyphPositionStatus
