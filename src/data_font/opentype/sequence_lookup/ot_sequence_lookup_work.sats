staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/substitution/gsub_sequence_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_types.sats"
fun ot_sequence_action_matches{kind:int}(domain: GsubSequenceDomain(kind),action: OtLookupKind(1)): bool
fun ot_sequence_tables_make{n:nat}(count: int(n)): OtSequenceTables(n,0)
fun ot_sequence_tables_append{n,i:nat | i < n}(tables: OtSequenceTables(n,i),info: GsubSequenceInfo): OtSequenceTables(n,i+1)
fun ot_sequence_tables_get{n:nat}(tables: !OtSequenceTables(n,n),index: int): GsubSequenceInfo
fun ot_sequence_tables_dispose{n,i:nat}(tables: OtSequenceTables(n,i)): void
fun ot_sequence_tables_read{kind:int}(b: !Buf,header: OtLookupInfo(1),glyphs: int,
  domain: GsubSequenceDomain(kind)): OtSequenceTablesRead
fun ot_sequence_payload{kind:int}(b: !Buf,span: OtSpan,action: OtLookupKind(1),
  glyphs: int,domain: GsubSequenceDomain(kind),remaining: &int >> _): GsubSequencesRead(kind)
