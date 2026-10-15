staload "mem.sats"
staload "data_font/opentype_types.sats"

typedef OtRegionAxisCoords = @{
  startCoord=int,
  peakCoord=int,
  endCoord=int
}

typedef OtVariationRegionList = @{
  span=OtSpan,
  axisCount=int,
  regionCount=int
}

typedef OtItemVarDataInfo = @{
  span=OtSpan,
  itemCount=int,
  wordDeltaCount=int,
  regionCount=int
}

typedef OtItemVarStoreInfo = @{
  span=OtSpan,
  regions=OtVariationRegionList,
  dataCount=int
}

datavtype OtItemVarStoreRead =
  | ItemVarStoreAccepted of OtItemVarStoreInfo
  | ItemVarStoreRejected of OtError
