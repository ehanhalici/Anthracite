staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/substitution/gsub_ligature_types.sats"
datavtype OtLigationTables(int,int) = {n,i:nat | i <= n}{l:addr} OtLigationTables(n,i) of
  (arrayptr(GsubLigatureInfo,l,n),int(n),int(i))
datavtype OtLigationTablesRead = {n:nat} LigationTablesAccepted of OtLigationTables(n,n) | LigationTablesRejected of OtError
datavtype OtLigationLookup = {n:nat} OtLigationLookup of (OtLookupInfo(1),int,int,OtLigationTables(n,n))
datavtype OtLigationLookupRead = LigationLookupAccepted of OtLigationLookup | LigationLookupRejected of OtError
