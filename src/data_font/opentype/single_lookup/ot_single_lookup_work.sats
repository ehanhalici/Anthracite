staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup_types.sats"
fun ot_single_header_parse(b: !Buf,span: OtSpan): OtSingleHeaderRead
fun ot_single_tables_make{n:nat}(count: int(n)): OtSingleTables(n,0)
fun ot_single_tables_append{n,i:nat | i < n}(tables: OtSingleTables(n,i),info: GsubSingleInfo): OtSingleTables(n,i+1)
fun ot_single_tables_get{n:nat}(tables: !OtSingleTables(n,n),index: int): GsubSingleInfo
fun ot_single_tables_dispose{n,i:nat}(tables: OtSingleTables(n,i)): void
fun ot_single_tables_read(b: !Buf,header: OtSingleHeader,glyphs: int): OtSingleTablesRead
fun ot_single_payload(b: !Buf,span: OtSpan,envelope: OtSingleEnvelope,glyphs: int): GsubSingleRead
