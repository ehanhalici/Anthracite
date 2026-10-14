staload "data_font/opentype_types.sats"
datatype GposMarkFields = MarkRecordFields | AttachmentFields
typedef GposMarkInfo = @{marks=OtCoverageInfo,targets=OtCoverageInfo,
  markArray=OtSpan,targetArray=OtSpan,classes=int,markCount=int,targetCount=int,glyphs=int}
datavtype GposMarkHeaderRead = MarkHeaderAccepted of GposMarkInfo | MarkHeaderRejected of OtError
