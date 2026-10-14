staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/gsub_reverse_types.sats"
datavtype OtReverseSlot = ReverseSlotVacant | ReverseSlot of GsubReverse
datavtype OtReverseSlotRead = ReverseSlotAccepted of OtReverseSlot | ReverseSlotRejected of OtError
datavtype OtReverseTables(int,int) = {n,i:nat | i <= n}{l:addr} OtReverseTables(n,i) of
  (array_v(OtReverseSlot,l,n),mfree_gc_v(l) | ptr(l),int(n),int(i))
datavtype OtReverseTablesRead = {n:nat} ReverseTablesAccepted of OtReverseTables(n,n) | ReverseTablesRejected of OtError
datavtype OtReverseLookup = {n:nat} OtReverseLookup of (OtLookupInfo(1),int,OtContextLimits,OtReverseTables(n,n))
datavtype OtReverseLookupRead = ReverseLookupAccepted of OtReverseLookup | ReverseLookupRejected of OtError
