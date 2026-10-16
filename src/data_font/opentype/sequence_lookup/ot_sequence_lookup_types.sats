staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/substitution/gsub_sequence_types.sats"
datavtype OtSequenceTables(int,int) = {n:nat}{i:nat | i <= n}{l:addr} OtSequenceTables(n,i) of
  (arrayptr(GsubSequenceInfo,l,n),int(n),int(i))
datavtype OtSequenceTablesRead = {n:nat} SequenceTablesAccepted of OtSequenceTables(n,n)
  | SequenceTablesRejected of OtError
datavtype OtSequenceLookup(kind:int) = {n:nat} OtSequenceLookup(kind) of
  (OtLookupInfo(1),int,OtSequenceTables(n,n))
datavtype OtSequenceLookupRead(kind:int) = SequenceLookupAccepted(kind) of OtSequenceLookup(kind)
  | SequenceLookupRejected(kind) of OtError
