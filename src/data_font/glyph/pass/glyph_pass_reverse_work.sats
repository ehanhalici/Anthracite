staload "mem.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/pass/glyph_pass_window_types.sats"
staload "data_font/opentype/reverse_lookup/ot_reverse_lookup_types.sats"
typedef GlyphReverseMatch = @{status=GlyphPassStatus,matched=bool,glyph=int}
typedef GlyphReverseCount = @{status=GlyphPassStatus,visited=int,matches=int}
fun glyph_reverse_window_status(status: GlyphWindowStatus): GlyphPassStatus
fun glyph_reverse_query{n:nat}(b: !Buf,t: !OtReverseLookup,m: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,selection: GlyphSelection,node: int,w: !GlyphContextWindow,
  remaining: &int >> int): GlyphReverseMatch
fun glyph_reverse_walk{n:nat}(b: !Buf,t: !OtReverseLookup,m: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,selection: GlyphSelection,w: !GlyphContextWindow,remaining: &int >> int): GlyphReverseCount
fun glyph_reverse_execute{n:nat}(b: !Buf,t: !OtReverseLookup,m: !GlyphMetadata,s: GlyphStorage(n),
  meta: GlyphRunMeta,selection: GlyphSelection,w: GlyphContextWindow,remaining: &int >> int): GlyphPassResult(1)
