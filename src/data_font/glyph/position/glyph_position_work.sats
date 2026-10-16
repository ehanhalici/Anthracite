staload "mem.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
fun glyph_position_ready(status: GlyphPositionStatus): bool
fun glyph_position_checked(value: llint): GlyphCoordinate
fun glyph_position_sum(first: int,second: int): GlyphCoordinate
fun glyph_position_change(xa: GlyphCoordinate,ya: GlyphCoordinate,xo: GlyphCoordinate,yo: GlyphCoordinate,
  old: GlyphPosition): GlyphPositionChange
fun glyph_position_value(b: !Buf,scale: GlyphScale,value: OtValueInfo,old: GlyphPosition): GlyphPositionChange
fun glyph_position_cache_make{n:nat}(count: int(n)): GlyphPositionCache(n)
fun glyph_position_cache_get{n:nat}(cache: !GlyphPositionCache(n),index: int): GlyphPosition
fun glyph_position_cache_set{n:nat}(cache: !GlyphPositionCache(n),index: int,value: GlyphPosition): void
fun glyph_position_cache_dispose{n:nat}(cache: GlyphPositionCache(n)): void
fun glyph_position_cache_copy{n,m:nat}(storage: !GlyphStorage(n),cache: !GlyphPositionCache(m),count: int): void
fun glyph_position_cache_commit{n,m:nat}(cache: !GlyphPositionCache(n),storage: !GlyphStorage(m),count: int): void
fun glyph_position_nominal{n,m:nat}(face: !SfntFace,scale: GlyphScale,storage: !GlyphStorage(n),
  meta: GlyphRunMeta,cache: !GlyphPositionCache(m)): GlyphPositionStatus
fun glyph_position_nominal_bytes{n,m:nat}(b: !Buf,info: SfntInfo,scale: GlyphScale,storage: !GlyphStorage(n),
  meta: GlyphRunMeta,cache: !GlyphPositionCache(m)): GlyphPositionStatus
