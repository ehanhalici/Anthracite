staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
fun ot_layout_parse{kind:int}(b: !Buf,span: OtSpan,domain: OtLayoutDomain(kind),caps: OtGdefCapabilities): OtLayoutRead(kind)
fun ot_layout_info{kind:int}(table: !OtLayoutTable(kind,0)): OtLayoutInfo
