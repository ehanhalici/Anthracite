staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_cov_cache_types.sats"
typedef GsubReverseInfo(b:int,l:int) = @{span=OtSpan,back=int(b),look=int(l),output=int,count=int,glyphs=int}
datavtype GsubReverse =
  | {b,l:nat} GsubReverse of (GsubReverseInfo(b,l),OtCoverageCache(b+l+1,b+l+1))
datavtype GsubReverseRead = ReverseAccepted of GsubReverse | ReverseRejected of OtError
