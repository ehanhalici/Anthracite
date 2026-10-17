staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
datavtype OtLayoutHeaderRead = HeaderAccepted of OtLayoutInfo | HeaderRejected of OtError
fun ot_layout_header_parse(b: !Buf,span: OtSpan): OtLayoutHeaderRead
