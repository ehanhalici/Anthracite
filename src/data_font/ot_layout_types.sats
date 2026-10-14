staload "mem.sats"
staload "data_font/opentype_types.sats"
datatype OtLayoutDomain(int) = OtSubstitution(1) | OtPositioning(2)
datatype OtLookupKind(int) =
  | SubSingle(1) | SubMultiple(1) | SubAlternate(1) | SubLigature(1)
  | SubContext(1) | SubChained(1) | SubExtension(1) | SubReverse(1)
  | PosSingle(2) | PosPair(2) | PosCursive(2) | PosMarkBase(2) | PosMarkLigature(2)
  | PosMarkMark(2) | PosContext(2) | PosChained(2) | PosExtension(2)
(* Four printable ASCII bytes are serialization data, not string-valued modes. *)
typedef OtTag = @{code=int}
typedef OtRecordList = @{span=OtSpan,header=int,count=int}
typedef OtLayoutInfo = @{span=OtSpan,scripts=OtRecordList,features=OtRecordList,lookups=OtSpan,lookupCount=int}
typedef OtLanguageInfo = @{span=OtSpan,count=int,required=OtIndex}
typedef OtFeatureInfo = @{span=OtSpan,count=int,parameters=OtChild}
typedef OtGdefCapabilities = @{classes=bool,attachments=bool,markSets=int}
typedef OtLookupInfo(kind:int) = @{span=OtSpan,action=OtLookupKind(kind),
  flags=OtLookupFlags,count=int,markSet=int}
(* Phase 0 validates topology and lookup headers only. It is not an executable
   shaping table; subtable payloads and FeatureParams need their own readers. *)
datavtype OtLayoutTable(kind:int,phase:int) = OtLayoutStructure(kind,0) of OtLayoutInfo
datavtype OtLayoutRead(kind:int) =
  | LayoutAccepted(kind) of OtLayoutTable(kind,0) | LayoutRejected(kind) of OtError
datavtype OtFeatureSet = OtFeatureSet of (Buf,int)
datavtype OtFeatureSetRead = FeatureSetAccepted of OtFeatureSet | FeatureSetRejected of OtErrorReason
(* Ascending lookup IDs and CSR feature-owner indices, not per-glyph masks.
   Later script stages derive glyph eligibility from this preserved provenance. *)
datavtype OtStagePlan(kind:int) = OtStagePlan(kind) of (Buf,Buf,Buf,int,int)
