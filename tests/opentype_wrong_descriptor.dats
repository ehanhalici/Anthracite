staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_classdef.sats"
staload "data_font/opentype_device.sats"
fun wrong_coverage(b: !Buf,c: OtCoverageInfo): int = ot_classdef_value(b,c,0)
fun wrong_variation(b: !Buf,d: !OtDeviceRead): int = ot_device_pixels(b,d,16)
