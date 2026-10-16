staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
datavtype OtValueCache(int,int) =
  | {n:nat}{i:nat | i <= n}{l:addr} OtValueCache(n,i) of
      (arrayptr(OtValueInfo,l,n),int(n),int(i))
datavtype OtValueCacheRead =
  | {n:nat} ValueCacheAccepted of OtValueCache(n,n) | ValueCacheRejected of OtError
