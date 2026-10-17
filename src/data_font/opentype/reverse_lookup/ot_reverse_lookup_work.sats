staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_extension.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/opentype/reverse_lookup/ot_reverse_lookup_types.sats"
fun ot_reverse_slot_dispose(slot: OtReverseSlot): void
fun ot_reverse_tables_exchange{n,i:nat | i < n}(t: !OtReverseTables(n,n),index: int(i),slot: &OtReverseSlot >> OtReverseSlot): void
fun ot_reverse_slot_list_dispose{n:nat}(xs: list_vt(OtReverseSlot,n)): void
fun ot_reverse_tables_make{n:nat}(xs: list_vt(OtReverseSlot,n),count: int(n)): OtReverseTables(n,n)
fun ot_reverse_tables_dispose{n,i:nat | i <= n}(tables: OtReverseTables(n,i)): void
fun ot_reverse_slot_parse(b: !Buf,h: OtLookupInfo(1),glyphs: int,index: int): OtReverseSlotRead
fun ot_reverse_slot_limits(slot: !OtReverseSlot): OtContextLimits
fun ot_reverse_slot_bytes(slot: !OtReverseSlot): llint
fun ot_reverse_tables_read(b: !Buf,h: OtLookupInfo(1),glyphs: int,limits: &OtContextLimits >> OtContextLimits): OtReverseTablesRead
