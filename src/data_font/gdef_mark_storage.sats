staload "mem.sats"
staload "data_font/opentype_types.sats"
fun gdef_mark_descriptor_put(descriptors: !Buf,index: int,coverage: OtCoverageInfo): void
fun gdef_mark_descriptor_get(descriptors: !Buf,index: int): OtCoverageInfo
