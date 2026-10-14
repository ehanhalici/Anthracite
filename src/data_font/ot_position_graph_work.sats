staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_extension.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/ot_position_graph_types.sats"
fun ot_position_graph_child(b: !Buf,h: OtLookupInfo(2),index: int): OtExtensionRead(2)
fun ot_position_graph_entry(b: !Buf,span: OtSpan,glyphs: int,lookups: int): OtPositionGraphEntryRead
fun ot_position_context_tables(b: !Buf,h: OtLookupInfo(2),glyphs: int,lookups: int,
  mode: OtContextMode): OtPositionContextTablesRead
fun ot_position_context_dispose(slot: OtPositionContext): void
fun ot_position_context_list_dispose{n:nat}(xs: list_vt(OtPositionContext,n)): void
fun ot_position_contexts_make{n:nat}(xs: list_vt(OtPositionContext,n),n: int(n)): OtPositionContexts(n,n)
fun ot_position_contexts_dispose{n,i:nat | i <= n}(t: OtPositionContexts(n,i)): void
fun ot_position_graph_entry_dispose(entry: OtPositionGraphEntry): void
fun ot_position_graph_list_dispose{n:nat}(xs: list_vt(OtPositionGraphEntry,n)): void
fun ot_position_graph_entries_make{n:nat}(xs: list_vt(OtPositionGraphEntry,n),n: int(n)): OtPositionGraphEntries(n,n)
fun ot_position_graph_entries_dispose{n,i:nat | i <= n}(t: OtPositionGraphEntries(n,i)): void
fun ot_position_graph_entry_limits(entry: !OtPositionGraphEntry): OtContextLimits
fun ot_position_graph_entry_bytes(entry: !OtPositionGraphEntry): llint
fun ot_position_graph_limits(first: OtContextLimits,second: OtContextLimits): OtContextLimits
