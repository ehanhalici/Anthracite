staload "mem.sats"
staload "data_font/opentype_types.sats"
(* Font units and device pixels are distinct quantities. Variation references
   stay explicit until an ItemVariationStore owner resolves them. *)
datatype OtValueField = ValueXPlace | ValueYPlace | ValueXAdvance | ValueYAdvance
  | ValueXPlaceDevice | ValueYPlaceDevice | ValueXAdvanceDevice | ValueYAdvanceDevice
typedef OtValueFormat = @{size=int,xp=int,yp=int,xa=int,ya=int,xd=int,yd=int,xad=int,yad=int}
datavtype OtValueFormatRead = ValueFormatAccepted of OtValueFormat | ValueFormatRejected
datatype OtAdjustmentKind = AdjustmentAbsent | AdjustmentDevice | AdjustmentVariation
typedef OtAdjustment = @{kind=OtAdjustmentKind,device=OtDeviceInfo,outer=int,inner=int}
datavtype OtAdjustmentRead = AdjustmentAccepted of OtAdjustment | AdjustmentRejected of OtError
datatype OtPixelKind = PixelResolved | PixelVariation
typedef OtPixelSample = @{kind=OtPixelKind,pixels=int,outer=int,inner=int}
typedef OtVector = @{xPlace=int,yPlace=int,xAdvance=int,yAdvance=int}
typedef OtValueInfo = @{units=OtVector,xPlace=OtAdjustment,yPlace=OtAdjustment,
  xAdvance=OtAdjustment,yAdvance=OtAdjustment}
datavtype OtValueRead = ValueAccepted of OtValueInfo | ValueRejected of OtError
typedef OtValueSample = @{units=OtVector,xPlace=OtPixelSample,yPlace=OtPixelSample,
  xAdvance=OtPixelSample,yAdvance=OtPixelSample}
datatype OtAnchorKind = AnchorCoordinates | AnchorContour | AnchorDevices
typedef OtAnchorInfo = @{kind=OtAnchorKind,x=int,y=int,point=int,dx=OtAdjustment,dy=OtAdjustment}
datavtype OtAnchorRead = AnchorAccepted of OtAnchorInfo | AnchorRejected of OtError
