staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_value_types.sats"
fun ot_value_signed16(raw: int): int
fun ot_value_units(b: !Buf,parent: OtSpan,at: int,format: OtValueFormat): OtVector
fun ot_value_device_offset(b: !Buf,parent: OtSpan,at: int,field: int): int
