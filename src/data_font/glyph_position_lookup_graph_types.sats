staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_pair_work.sats"
staload "mem.sats"
datatype GlyphPositionLookupGraphState = GraphEnter | GraphActions
datatype GlyphPositionLookupGraphStepKind = GraphCompleted | GraphNested
typedef GlyphPositionLookupGraphStep = @{kind=GlyphPositionLookupGraphStepKind,status=GlyphPositionStatus,
  next=int,matched=bool,context=OtContextMatch(2)}
typedef GlyphPositionLookupGraphFrame = @{state=GlyphPositionLookupGraphState,lookup=int,node=int,
  action=int,next=int,matched=bool,context=OtContextMatch(2)}
datavtype GlyphPositionLookupGraphStack = {n:nat}{l:addr} GlyphPositionLookupGraphStack of
  (arrayptr(GlyphPositionLookupGraphFrame,l,n),int(n),int)
datavtype GlyphPositionLookupGraphMap = GlyphPositionLookupGraphMap of (Buf,Buf,Buf,int,int)
typedef GlyphPositionLookupGraphCapacity = @{status=GlyphPositionStatus,cells=int,frames=int}
datatype GlyphPositionLookupGraphEventKind = GraphContinue | GraphReturned | GraphFault
typedef GlyphPositionLookupGraphEvent = @{kind=GlyphPositionLookupGraphEventKind,depth=int,result=GlyphPairStep}
