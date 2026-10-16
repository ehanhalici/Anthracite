staload "data_font/glyph/position/glyph_position_types.sats"
datatype GlyphPositionVisit = PositionFresh | PositionVisiting | PositionResolved
datatype GlyphPositionGraphMode = PositionCross | PositionFinal of GlyphPositionDirection
typedef GlyphPositionOrigin = @{x=llint,y=llint}
typedef GlyphPositionPathStep = @{status=GlyphPositionStatus,node=int,depth=int}
datavtype GlyphPositionGraph(int) = {n:nat}{a,b,c:addr} GlyphPositionGraph(n) of
  (int(n),arrayptr(GlyphPositionOrigin,a,n),arrayptr(GlyphPositionVisit,b,n),arrayptr(int,c,n))
