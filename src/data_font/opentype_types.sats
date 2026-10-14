staload "mem.sats"
(* Borrowed descriptors refer to an immutable parent font buffer. Owners keep
   descriptors with that buffer; no subtable bytes are cloned or globally cached. *)
typedef OtSpan = @{offset=int,length=int}
datatype OtChildKind = ChildMissing | ChildPresent | ChildInvalid
typedef OtChild = @{kind=OtChildKind,span=OtSpan}
datatype OtEncoding = OtList | OtRanges
datatype OtErrorReason = OtBounds | OtFormat | OtGlyphDomain | OtOrder | OtCoverageIndex | OtPadding
  | OtReference | OtUnsupported | OtCapacity
typedef OtError = @{reason=OtErrorReason,offset=int}
typedef OtRange = @{first=int,last=int,value=int}
typedef OtIndex = @{found=bool,index=int}
typedef OtCoverageInfo = @{span=OtSpan,encoding=OtEncoding,count=int,total=int}
typedef OtClassInfo = @{span=OtSpan,encoding=OtEncoding,count=int,first=int,maximum=int}
datavtype OtCoverageRead = CoverageAccepted of OtCoverageInfo | CoverageRejected of OtError
datavtype OtClassRead = ClassAccepted of OtClassInfo | ClassRejected of OtError
datatype OtPacking = OtBits2 | OtBits4 | OtBits8
typedef OtDeviceInfo = @{span=OtSpan,packing=OtPacking,first=int,last=int}
datavtype OtDeviceRead =
  | DeviceAccepted of OtDeviceInfo | DeviceVariation of (int,int) | DeviceRejected of OtError
typedef OtLookupFlags = @{rtl=bool,ignoreBase=bool,ignoreLigature=bool,ignoreMarks=bool,
  useMarkSet=bool,attachment=int}
datavtype OtFlagsRead = FlagsAccepted of OtLookupFlags | FlagsRejected of OtErrorReason
