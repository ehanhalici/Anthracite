staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_extension.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/ot_substitution_graph_types.sats"
fun ot_substitution_graph_child(b: !Buf,h: OtLookupInfo(1),index: int): OtExtensionRead(1)
fun ot_substitution_graph_entry(b: !Buf,span: OtSpan,glyphs: int,lookups: int): OtSubstitutionGraphEntryRead
fun ot_substitution_direct(b: !Buf,h: OtLookupInfo(1),glyphs: int,a: OtLookupKind(1)): OtSubstitutionGraphEntryRead
fun ot_substitution_context_tables(b: !Buf,h: OtLookupInfo(1),glyphs: int,lookups: int,mode: OtContextMode): OtSubstitutionContextTablesRead
fun ot_substitution_context_dispose(slot: OtSubstitutionContext): void
fun ot_substitution_context_list_dispose{n:nat}(xs: list_vt(OtSubstitutionContext,n)): void
fun ot_substitution_contexts_make{n:nat}(xs: list_vt(OtSubstitutionContext,n),n: int(n)): OtSubstitutionContexts(n,n)
fun ot_substitution_contexts_dispose{n,i:nat | i <= n}(t: OtSubstitutionContexts(n,i)): void
fun ot_substitution_graph_entry_dispose(entry: OtSubstitutionGraphEntry): void
fun ot_substitution_graph_list_dispose{n:nat}(xs: list_vt(OtSubstitutionGraphEntry,n)): void
fun ot_substitution_graph_entries_make{n:nat}(xs: list_vt(OtSubstitutionGraphEntry,n),n: int(n)): OtSubstitutionGraphEntries(n,n)
fun ot_substitution_graph_entries_dispose{n,i:nat | i <= n}(t: OtSubstitutionGraphEntries(n,i)): void
fun ot_substitution_graph_entry_limits(entry: !OtSubstitutionGraphEntry): OtContextLimits
fun ot_substitution_graph_entry_bytes(entry: !OtSubstitutionGraphEntry): llint
fun ot_substitution_graph_limits(first: OtContextLimits,second: OtContextLimits): OtContextLimits
