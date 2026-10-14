staload "mem.sats"
staload "data_font/opentype_types.sats"
fun ot_device_parse(b: !Buf,span: OtSpan): OtDeviceRead
fun ot_device_pixels(b: !Buf,device: OtDeviceInfo,ppem: int): int
