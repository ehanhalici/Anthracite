staload "mem.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/substitution_graph/ot_substitution_graph_types.sats"
staload "data_font/opentype/position_lookup/ot_position_graph_types.sats"
staload "data_font/opentype/shape/ot_shape_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_text/unicode/unicode_db.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/normalization/normalization_types.sats"
datavtype NativeSubstitution = NativeSubMissing | NativeSubTables of (OtLayoutTable(1,0),OtSubstitutionGraph)
datavtype NativePositioning = NativePosMissing | NativePosTables of (OtLayoutTable(2,0),OtPositionGraph)
typedef NativeFaceIdentity = @{font=int,glyphs=int,units=int}
datavtype NativeShapeCache = NativeShapeCache of (GlyphMetadata,NativeSubstitution,NativePositioning,NativeFaceIdentity)
datavtype NativeShapeCacheRead = NativeCacheAccepted of NativeShapeCache | NativeCacheRejected of OtError
datavtype NativeSubPlan = NativeSubNoPlan | NativeSubPlan of OtShapeSchedule(1)
datavtype NativePosPlan = NativePosNoPlan | NativePosPlan of OtShapeSchedule(2)
typedef NativePlanInfo = @{face=NativeFaceIdentity,request=OtShapeRequest,masks=OtShapeMasks}
datavtype NativeShapePlan = NativeShapePlan of (NativeSubPlan,NativePosPlan,NativePlanInfo)
datavtype NativeShapePlanRead = NativePlanAccepted of NativeShapePlan | NativePlanRejected of OtError
datavtype NativeShapeText = NativeShapeText of (ScalarText,OtShapeProfile)
datavtype NativeShapeTextRead = NativeTextAccepted of NativeShapeText | NativeTextRejected of NormalizationError
datavtype NativeSubRead = NativeSubAccepted of NativeSubstitution | NativeSubRejected of OtError
datavtype NativePosRead = NativePosAccepted of NativePositioning | NativePosRejected of OtError
datavtype NativeSubPlanRead = NativeSubPlanAccepted of NativeSubPlan | NativeSubPlanRejected of OtError
datavtype NativePosPlanRead = NativePosPlanAccepted of NativePosPlan | NativePosPlanRejected of OtError
datavtype NativeShapeData = NativeShapeData of (UnicodeDb,PropertyMap(6),PropertyMap(8),PropertyMap(3))
datatype NativeShapeFailure = NativeShapeFace | NativeShapeNominal | NativeShapeSubstitution | NativeShapePositioning
typedef NativeShapeError = @{reason=NativeShapeFailure,edit=GlyphEditStatus,substitution=GlyphPassStatus,position=GlyphPositionStatus}
datavtype NativeShapeRead = NativeShapeAccepted of GlyphPositioned(1) | NativeShapeRejected of NativeShapeError
typedef NativeShapeScale = @{xPpem=int,yPpem=int}
