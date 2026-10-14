staload "data_font/glyph_run_types.sats"
datatype GlyphMaskKind = GlyphAll | GlyphMasked
typedef GlyphSelection = @{kind=GlyphMaskKind,mask=uint}
datatype GlyphPassStatus = GlyphPassApplied | GlyphPassDomain | GlyphPassReference | GlyphPassCapacity
datavtype GlyphPassResult(phase:int) = GlyphPassResult(phase) of
  (GlyphRun(phase),GlyphPassStatus,int,int)
