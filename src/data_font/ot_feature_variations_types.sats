staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"

typedef OtConditionFormat1 = @{
  axisIndex=int,
  filterMin=int,
  filterMax=int
}

typedef OtConditionSetInfo = @{
  span=OtSpan,
  count=int
}

typedef OtFeatureSubstRecord = @{
  featureIndex=int,
  alternate=OtChild
}

typedef OtFeatureTableSubstInfo = @{
  span=OtSpan,
  count=int
}

typedef OtFeatureVariationRecord = @{
  conditionSet=OtChild,
  substTable=OtChild
}

typedef OtFeatureVariationsInfo = @{
  span=OtSpan,
  count=int
}

datavtype OtFeatureVariationsRead =
  | FeatureVariationsAccepted of OtFeatureVariationsInfo
  | FeatureVariationsRejected of OtError
