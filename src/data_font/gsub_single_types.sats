staload "mem.sats"
staload "data_font/opentype_types.sats"
datatype GsubSingleEncoding = GsubDelta | GsubArray
typedef GsubSingleInfo = @{span=OtSpan,coverage=OtCoverageInfo,
  encoding=GsubSingleEncoding,delta=int,count=int,glyphs=int}
(* A payload-validated single-substitution capability, not a complete GSUB table.
   Its owner must retain the same immutable parent font buffer while querying. *)
datavtype GsubSingle = GsubSingle of GsubSingleInfo
datavtype GsubSingleRead = SingleAccepted of GsubSingle | SingleRejected of OtError
typedef GsubSingleResult = @{matched=bool,glyph=int}
