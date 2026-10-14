staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_value_cache_types.sats"
datatype GposSingleEncoding = PositionUniform | PositionIndexed
typedef GposSingleInfo = @{coverage=OtCoverageInfo,encoding=GposSingleEncoding,glyphs=int}
datavtype GposSingle = {n:nat} GposSingle of (GposSingleInfo,OtValueCache(n,n))
datavtype GposSingleRead = PositionSingleAccepted of GposSingle | PositionSingleRejected of OtError
typedef GposSingleView = @{matched=bool,value=OtValueInfo}
