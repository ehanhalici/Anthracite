staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/ot_ligation_lookup_types.sats"
fun ot_ligation_lookup_parse(b: !Buf,span: OtSpan,glyphs: int): OtLigationLookupRead
fun ot_ligation_lookup_info(t: !OtLigationLookup): OtLookupInfo(1)
fun ot_ligation_lookup_glyphs(t: !OtLigationLookup): int
fun ot_ligation_lookup_maximum(t: !OtLigationLookup): int
fun ot_ligation_lookup_dispose(t: OtLigationLookup): void
fun ot_ligation_lookup_query(b: !Buf,t: !OtLigationLookup,input: !Buf,count: int,start: int,remaining: &int >> _): GsubLigatureMatch
