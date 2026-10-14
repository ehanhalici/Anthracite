staload "mem.sats"
staload "data_font/opentype_types.sats"
(* One AttachPoint descriptor per AttachList glyph: borrowed font span plus
   the checked point count. Descriptors own compact storage, not font bytes.
   The AttachList coverage resolves glyph IDs to descriptor indices. *)
typedef GdefAttachPoint = @{span=OtSpan,count=int}
datavtype GdefAttachList = GdefAttachList of (Buf,int,OtCoverageInfo)
datavtype GdefAttachRead = GdefAttachAccepted of GdefAttachList | GdefAttachRejected of OtError
datatype GdefCaretKind = CaretCoordinate | CaretContour | CaretDevice
(* A CaretValue: signed design coordinate, a contour point index, or a
   coordinate plus a packed Device correction span borrowed from the font. *)
typedef GdefCaretValue = @{kind=GdefCaretKind,value=int,device=OtSpan}
(* One LigGlyph descriptor per covered ligature glyph. *)
typedef GdefLigGlyph = @{span=OtSpan,carets=int}
datavtype GdefLigCarets = GdefLigCarets of (Buf,int,OtCoverageInfo)
datavtype GdefLigCaretsRead = GdefLigCaretsAccepted of GdefLigCarets | GdefLigCaretsRejected of OtError
