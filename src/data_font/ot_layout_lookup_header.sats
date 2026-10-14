staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
datavtype OtLookupHeaderRead(kind:int) = LookupHeaderAccepted(kind) of OtLookupInfo(kind)
  | LookupHeaderRejected(kind) of OtError
fun ot_lookup_header_parse{kind:int}(b: !Buf,span: OtSpan,domain: OtLayoutDomain(kind)): OtLookupHeaderRead(kind)
fun ot_lookup_header_floor{kind:int}(header: OtLookupInfo(kind)): int
