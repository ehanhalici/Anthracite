staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/reverse_lookup/ot_reverse_lookup_types.sats"
fun ot_reverse_lookup_parse(b: !Buf,span: OtSpan,glyphs: int): OtReverseLookupRead
fun ot_reverse_lookup_dispose(lookup: OtReverseLookup): void
