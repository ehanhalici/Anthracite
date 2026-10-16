staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
datatype GdefVersion = Gdef10 | Gdef12 | Gdef13
datatype GdefGlyphKind = GlyphUnclassified | GlyphBase | GlyphLigature | GlyphMark | GlyphComponent
typedef GdefHeaderInfo = @{span=OtSpan,version=GdefVersion,classes=OtChild,attach=OtChild,
  carets=OtChild,markAttach=OtChild,markSets=OtChild,variations=OtChild}
datavtype GdefHeaderRead = GdefHeaderAccepted of GdefHeaderInfo | GdefHeaderRejected of OtError
typedef GdefClassMetadata = @{classes=OtClassInfo,attachment=OtClassInfo,defined=bool,attachmentDefined=bool}
datavtype GdefClassRead = GdefClassAccepted of GdefClassMetadata | GdefClassRejected of OtError
datavtype GdefMarkSets = GdefNoMarks | GdefMarkSets of (Buf,int)
datavtype GdefMarksRead = GdefMarksAccepted of GdefMarkSets | GdefMarksRejected of OtError
