staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_mark_matrix_types.sats"
staload "data_font/opentype/position/gpos_mark_ligature_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
typedef GlyphMarkStep = @{status=GlyphPositionStatus,matched=bool}
typedef GlyphMarkParent = @{status=GlyphPositionStatus,node=int}
fun glyph_position_is_mark(metadata: !GlyphMetadata,core: GlyphCore): bool
fun glyph_position_mark_flags(flags: OtLookupFlags): OtLookupFlags
fun glyph_position_mark_check(metadata: !GlyphMetadata,meta: GlyphRunMeta,glyphs: int,
  flags: OtLookupFlags,set: int): GlyphPositionStatus
fun glyph_position_mark_cross{n,m:nat}(s: !GlyphStorage(n),meta: GlyphRunMeta,cache: !GlyphPositionCache(m),node: int): GlyphCoordinate
fun glyph_position_mark_affinity{n:nat}(s: !GlyphStorage(n),meta: GlyphRunMeta,node: int,parent: int): bool
fun glyph_position_mark_component{n:nat}(s: !GlyphStorage(n),meta: GlyphRunMeta,node: int,parent: int,count: int): int
fun glyph_position_mark_base_accept{n:nat}(metadata: !GlyphMetadata,s: !GlyphStorage(n),core: GlyphCore,previous: int): bool
fun glyph_position_mark_matrix_step{n,m,kind:int | n >= 0; m >= 0}(b: !Buf,t: !GposMarkMatrix(kind),metadata: !GlyphMetadata,
  s: !GlyphStorage(n),meta: GlyphRunMeta,scale: GlyphScale,cache: !GlyphPositionCache(m),node: int,parent: int): GlyphMarkStep
fun glyph_position_mark_matrix_walk{n,m,kind:int | n >= 0; m >= 0}(b: !Buf,t: !GposMarkMatrix(kind),metadata: !GlyphMetadata,
  s: !GlyphStorage(n),meta: GlyphRunMeta,scale: GlyphScale,flags: OtLookupFlags,set: int,selection: GlyphSelection,
  cache: !GlyphPositionCache(m),matches: &int >> _): GlyphPositionStatus
fun glyph_position_mark_ligature_step{n,m:nat}(b: !Buf,t: !GposMarkLigature,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,cache: !GlyphPositionCache(m),node: int,parent: int): GlyphMarkStep
fun glyph_position_mark_ligature_walk{n,m:nat}(b: !Buf,t: !GposMarkLigature,metadata: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,scale: GlyphScale,flags: OtLookupFlags,set: int,selection: GlyphSelection,
  cache: !GlyphPositionCache(m),matches: &int >> _): GlyphPositionStatus
