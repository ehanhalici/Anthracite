staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_types.sats"
fun ot_position_payload_parse(b: !Buf,s: OtSpan,glyphs: int,action: OtLookupKind(2)): OtPositionPayloadRead
fun ot_position_payload_resolve(b: !Buf,s: OtSpan,glyphs: int,action: OtLookupKind(2)): OtPositionPayloadRead
fun ot_position_payload_dispose(payload: OtPositionPayload): void
fun ot_position_payload_bytes(payload: !OtPositionPayload): llint
fun ot_position_payload_action(payload: !OtPositionPayload): OtLookupKind(2)
fun ot_position_payload_charge(payload: !OtPositionPayload,remaining: &int >> _): bool
fun ot_position_tables_read(b: !Buf,h: OtLookupInfo(2),glyphs: int): OtPositionTablesRead
fun ot_position_tables_make{n:nat}(rows: list_vt(OtPositionPayload,n),count: int(n)): OtPositionTables(n,n)
fun ot_position_payload_list_dispose{n:nat}(rows: list_vt(OtPositionPayload,n)): void
fun ot_position_tables_dispose{n,i:nat | i <= n}(tables: OtPositionTables(n,i)): void
fun ot_position_tables_action{n:nat}(tables: !OtPositionTables(n,n),fallback: OtLookupKind(2)): OtLookupKind(2)
