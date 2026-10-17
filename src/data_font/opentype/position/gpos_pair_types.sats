staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
staload "data_font/opentype/position/gpos_value_cache_types.sats"
datatype GposPairProgress = PairContinueSecond | PairContinueFollowing
typedef GposPairFormat = @{first=OtValueFormat,second=OtValueFormat,stride=int,progress=GposPairProgress}
datavtype GposPairFormatRead = PairFormatAccepted of GposPairFormat | PairFormatRejected of OtError
typedef GposPairSet = @{span=OtSpan,count=int,start=int,floor=int}
datavtype GposPairSets(int,int) =
  | {n,i:nat | i <= n}{l:addr} GposPairSets(n,i) of (arrayptr(GposPairSet,l,n),int(n),int(i))
datavtype GposPairSetRead =
  | {n:nat} PairSetsAccepted of (GposPairSets(n,n),int) | PairSetsRejected of OtError
datavtype GposPairPartial(n:int) =
  | {i:nat | i <= n} PairValuesPartial(n) of OtValueCache(n,i) | PairValuesRejected(n) of OtError
typedef GposPairInfo = @{span=OtSpan,coverage=OtCoverageInfo,formats=GposPairFormat,
  firstClass=OtClassInfo,secondClass=OtClassInfo,firstCount=int,secondCount=int,glyphs=int}
datavtype GposPairs =
  | {n,m:nat} PairGlyphs of (GposPairInfo,GposPairSets(n,n),OtValueCache(m,m))
  | {n:nat} PairClasses of (GposPairInfo,OtValueCache(n,n))
  | PairNoOpClasses of GposPairInfo
datavtype GposPairRead = PairAccepted of GposPairs | PairRejected of OtError
typedef GposPairView = @{matched=bool,first=OtValueInfo,second=OtValueInfo,progress=GposPairProgress}
