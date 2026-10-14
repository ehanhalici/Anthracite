staload "mem.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/glyph_position_types.sats"
typedef GlyphAnchorOffset = @{status=GlyphPositionStatus,x=int,y=int}
(* Native unhinted static outlines: format 2 uses its design coordinates.
   A future hinted rasterizer must supply contour-point anchor resolution. *)
fun glyph_position_anchor_delta(b: !Buf,scale: GlyphScale,mark: OtAnchorInfo,target: OtAnchorInfo): GlyphAnchorOffset
fun glyph_position_anchor_sample(b: !Buf,scale: GlyphScale,anchor: OtAnchorInfo): GlyphAnchorOffset
fun glyph_position_anchor_attach{n:nat}(b: !Buf,scale: GlyphScale,cache: !GlyphPositionCache(n),
  cross: GlyphCoordinate,node: int,parent: int,mark: OtAnchorSlot,target: OtAnchorSlot): GlyphPositionStatus
