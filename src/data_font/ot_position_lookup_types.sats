staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/gpos_single_types.sats"
staload "data_font/gpos_pair_types.sats"
staload "data_font/gpos_cursive_types.sats"
staload "data_font/gpos_mark_matrix_types.sats"
staload "data_font/gpos_mark_ligature_types.sats"
(* Vacant exists only during an exclusive, immediately restored native-array
   loan. No public query accepts a partially ingested table owner. *)
datavtype OtPositionPayload = PositionPayloadVacant
  | PositionPayloadSingle of GposSingle | PositionPayloadPair of GposPairs
  | PositionPayloadCursive of GposCursive | PositionPayloadBase of GposMarkMatrix(4)
  | PositionPayloadLigature of GposMarkLigature | PositionPayloadMark of GposMarkMatrix(6)
datavtype OtPositionPayloadRead = PositionPayloadAccepted of OtPositionPayload | PositionPayloadRejected of OtError
datavtype OtPositionTables(int,int) = {n,i:nat | i <= n}{l:addr} OtPositionTables(n,i) of
  (array_v(OtPositionPayload,l,n),mfree_gc_v(l) | ptr(l),int(n),int(i))
datavtype OtPositionTablesRead = {n:nat} PositionTablesAccepted of OtPositionTables(n,n) | PositionTablesRejected of OtError
datavtype OtPositionLookup = {n:nat} OtPositionLookup of (OtLookupInfo(2),OtLookupKind(2),int,OtPositionTables(n,n))
datavtype OtPositionLookupRead = PositionLookupAccepted of OtPositionLookup | PositionLookupRejected of OtError
