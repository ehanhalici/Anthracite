staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_types.sats"
datavtype OtPositionContext = PositionContextVacant | PositionContext of (OtContextProgram(2),OtContextLimits)
datavtype OtPositionContexts(int,int) = {n,i:nat | i <= n}{l:addr} OtPositionContexts(n,i) of
  (array_v(OtPositionContext,l,n),mfree_gc_v(l) | ptr(l),int(n),int(i))
datavtype OtPositionContextRead = ContextSlotAccepted of OtPositionContext | ContextSlotRejected of OtError
datavtype OtPositionContextTablesRead = {n:nat} ContextTablesAccepted of OtPositionContexts(n,n)
  | ContextTablesRejected of OtError
datavtype OtPositionGraphEntry = PositionGraphVacant | PositionGraphDirect of OtPositionLookup
  | {n:nat} PositionGraphContext of (OtLookupInfo(2),OtPositionContexts(n,n))
datavtype OtPositionGraphEntryRead = GraphEntryAccepted of OtPositionGraphEntry | GraphEntryRejected of OtError
datavtype OtPositionGraphEntries(int,int) = {n,i:nat | i <= n}{l:addr} OtPositionGraphEntries(n,i) of
  (array_v(OtPositionGraphEntry,l,n),mfree_gc_v(l) | ptr(l),int(n),int(i))
datavtype OtPositionGraph = {n:nat} OtPositionGraph of (int,int,OtContextLimits,OtPositionGraphEntries(n,n))
datavtype OtPositionGraphRead = PositionGraphAccepted of OtPositionGraph | PositionGraphRejected of OtError
