staload "data_font/glyph/run/glyph_run_types.sats"
datatype GlyphPositionStatus = PositionReady | PositionDomain | PositionReference
  | PositionCapacity | PositionOverflow | PositionVariation
typedef GlyphScale = @{units=int,xPpem=int,yPpem=int}
typedef GlyphCoordinate = @{status=GlyphPositionStatus,value=int}
typedef GlyphPositionChange = @{status=GlyphPositionStatus,value=GlyphPosition}
datatype GlyphPositionDirection = PositionLTR | PositionRTL
datavtype GlyphPositioned(phase:int) =
  | PositionAccumulating(0) of (GlyphRun(2),GlyphScale)
  | PositionFrozen(1) of (GlyphRun(3),GlyphScale,GlyphPositionDirection)
datavtype GlyphPositionRead = PositionInitialized of GlyphPositioned(0)
  | PositionRejected of (GlyphRun(2),GlyphPositionStatus)
datavtype GlyphPositionResult = GlyphPositionResult of (GlyphPositioned(0),GlyphPositionStatus,int,int)
datavtype GlyphPositionFinished = PositionFinished of GlyphPositioned(1)
  | PositionUnfinished of (GlyphPositioned(0),GlyphPositionStatus)
datavtype GlyphPositionCache(int) = {n:nat}{l:addr} GlyphPositionCache(n) of (arrayptr(GlyphPosition,l,n),int(n))
