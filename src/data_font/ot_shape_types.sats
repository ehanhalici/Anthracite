staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
datatype OtShapeProfile = ShapeCommonHorizontal | ShapeArabicHorizontal
datatype OtShapeStage = ShapeVariation | ShapeComposition | ShapeIsolated | ShapeFinal
  | ShapeMedial | ShapeInitial | ShapeRequiredLigatures | ShapeContextual | ShapeStandard | ShapePositioning
datatype OtShapeDirection = ShapeLTR | ShapeRTL
datatype OtShapeLanguage = ShapeDefaultLanguage | ShapeNamedLanguage of OtTag
typedef OtShapeRequest = @{profile=OtShapeProfile,script=OtTag,language=OtShapeLanguage,direction=OtShapeDirection}
typedef OtShapeMasks = @{initial=uint,medial=uint,final=uint,isolated=uint,mirror=uint}
typedef OtShapeLookup = @{lookup=int,stage=OtShapeStage,selection=GlyphSelection}
typedef OtShapeInfo = @{font=int,glyphs=int,count=int}
datavtype OtShapeSchedule(kind:int) = {n:nat} OtShapeSchedule(kind) of (arrayptr(OtShapeLookup,n),int(n),OtShapeInfo)
datavtype OtShapeRead(kind:int) = ShapeAccepted(kind) of OtShapeSchedule(kind) | ShapeRejected(kind) of OtError
