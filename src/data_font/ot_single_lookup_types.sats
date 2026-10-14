staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gsub_single_types.sats"
datatype OtSingleEnvelope = SingleDirect | SingleExtended
typedef OtSingleHeader = @{span=OtSpan,envelope=OtSingleEnvelope,flags=OtLookupFlags,count=int,floor=int,markSet=int}
datavtype OtSingleHeaderRead = SingleHeaderAccepted of OtSingleHeader | SingleHeaderRejected of OtError
datavtype OtSingleTables(int,int) = {n:nat}{i:nat | i <= n}{l:addr} OtSingleTables(n,i) of
  (arrayptr(GsubSingleInfo,l,n),int(n),int(i))
datavtype OtSingleTablesRead = {n:nat} SingleTablesAccepted of OtSingleTables(n,n) | SingleTablesRejected of OtError
datavtype OtSingleLookup = {n:nat} OtSingleLookup of (OtSingleHeader,int,OtSingleTables(n,n))
datavtype OtSingleLookupRead = SingleLookupAccepted of OtSingleLookup | SingleLookupRejected of OtError
