staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/ot_ligation_lookup_types.sats"
fun ot_ligation_tables_make{n:nat}(n: int(n)): OtLigationTables(n,0)
fun ot_ligation_tables_append{n,i:nat | i < n}(t: OtLigationTables(n,i),info: GsubLigatureInfo): OtLigationTables(n,i+1)
fun ot_ligation_tables_get{n,i:nat | i <= n}(t: !OtLigationTables(n,i),index: int): GsubLigatureInfo
fun ot_ligation_tables_dispose{n,i:nat | i <= n}(t: OtLigationTables(n,i)): void
fun ot_ligation_tables_read(b: !Buf,h: OtLookupInfo(1),glyphs: int,maximum: &int >> _): OtLigationTablesRead
fun ot_ligation_payload(b: !Buf,s: OtSpan,glyphs: int,action: OtLookupKind(1)): GsubLigaturesRead
fun ot_ligation_charge(b: !Buf,info: GsubLigatureInfo,remaining: &int >> _): bool
fun ot_ligation_tables_query{n:nat}(b: !Buf,t: !OtLigationTables(n,n),input: !Buf,count: int,start: int,remaining: &int >> _): GsubLigatureMatch
fun ot_ligation_tables_input{n:nat}(b: !Buf,t: !OtLigationTables(n,n),glyph: int,remaining: &int >> _): GsubLigatureInputBound
