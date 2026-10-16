staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_cursive_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_anchor.sats"
typedef GlyphCursiveChange = @{status=GlyphPositionStatus,first=GlyphPosition,second=GlyphPosition}
typedef GlyphCursiveStep = @{status=GlyphPositionStatus,matched=bool}
fun glyph_position_cursive_main(d: GlyphPositionDirection,a: GlyphPosition,c: GlyphPosition,
  exit: GlyphAnchorOffset,entry: GlyphAnchorOffset): GlyphCursiveChange
fun glyph_position_cursive_detached(p: GlyphPosition): GlyphPosition
fun glyph_position_cursive_attached(p: GlyphPosition,parent: int,y: int): GlyphPosition
fun glyph_position_cursive_reverse{n,m:nat}(s: !GlyphStorage(n),meta: GlyphRunMeta,c: !GlyphPositionCache(m),child: int,parent: int): GlyphPositionStatus
fun glyph_position_cursive_connect{n,m:nat}(s: !GlyphStorage(n),meta: GlyphRunMeta,c: !GlyphPositionCache(m),
  flags: OtLookupFlags,first: int,second: int,delta: GlyphAnchorOffset): GlyphPositionStatus
fun glyph_position_cursive_step{n,m:nat}(b: !Buf,t: !GposCursive,s: !GlyphStorage(n),meta: GlyphRunMeta,scale: GlyphScale,
  c: !GlyphPositionCache(m),f: OtLookupFlags,d: GlyphPositionDirection,first: int,second: int): GlyphCursiveStep
fun glyph_position_cursive_walk{n,m:nat}(b: !Buf,t: !GposCursive,metadata: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,scale: GlyphScale,f: OtLookupFlags,set: int,selection: GlyphSelection,d: GlyphPositionDirection,
  c: !GlyphPositionCache(m),matches: &int >> _): GlyphPositionStatus
