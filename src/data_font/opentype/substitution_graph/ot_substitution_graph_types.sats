staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_types.sats"
staload "data_font/opentype/ligation_lookup/ot_ligation_lookup_types.sats"
staload "data_font/opentype/reverse_lookup/ot_reverse_lookup_types.sats"
datavtype OtSubstitutionContext = SubstitutionContextVacant | SubstitutionContext of (OtContextProgram(1),OtContextLimits)
datavtype OtSubstitutionContexts(int,int) = {n,i:nat | i <= n}{l:addr} OtSubstitutionContexts(n,i) of
  (array_v(OtSubstitutionContext,l,n),mfree_gc_v(l) | ptr(l),int(n),int(i))
datavtype OtSubstitutionContextRead = SubContextSlotAccepted of OtSubstitutionContext | SubContextSlotRejected of OtError
datavtype OtSubstitutionContextTablesRead = {n:nat} SubContextTablesAccepted of OtSubstitutionContexts(n,n)
  | SubContextTablesRejected of OtError
datavtype OtSubstitutionGraphEntry = SubstitutionGraphVacant
  | SubstitutionGraphSingle of (OtLookupInfo(1),OtSingleLookup)
  | SubstitutionGraphMultiple of (OtLookupInfo(1),OtSequenceLookup(2))
  | SubstitutionGraphAlternate of (OtLookupInfo(1),OtSequenceLookup(3))
  | SubstitutionGraphLigature of (OtLookupInfo(1),OtLigationLookup)
  | SubstitutionGraphReverse of (OtLookupInfo(1),OtReverseLookup)
  | {n:nat} SubstitutionGraphContext of (OtLookupInfo(1),OtSubstitutionContexts(n,n))
datavtype OtSubstitutionGraphEntryRead = SubGraphEntryAccepted of OtSubstitutionGraphEntry | SubGraphEntryRejected of OtError
datavtype OtSubstitutionGraphEntries(int,int) = {n,i:nat | i <= n}{l:addr} OtSubstitutionGraphEntries(n,i) of
  (array_v(OtSubstitutionGraphEntry,l,n),mfree_gc_v(l) | ptr(l),int(n),int(i))
datavtype OtSubstitutionGraph = {n:nat} OtSubstitutionGraph of (int,int,OtContextLimits,OtSubstitutionGraphEntries(n,n))
datavtype OtSubstitutionGraphRead = SubstitutionGraphAccepted of OtSubstitutionGraph | SubstitutionGraphRejected of OtError
