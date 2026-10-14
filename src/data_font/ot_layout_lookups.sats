staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
fun ot_lookup_kind_of{kind:int}(domain: OtLayoutDomain(kind),code: int): Option_vt(OtLookupKind(kind))
fun ot_lookup_kind_code{kind:int}(action: OtLookupKind(kind)): int
fun ot_lookup_dependencies(flags: OtLookupFlags,set: int,caps: OtGdefCapabilities): bool
fun ot_lookup_span(b: !Buf,info: OtLayoutInfo,index: int): OtChild
fun ot_lookup_info{kind:int}(b: !Buf,span: OtSpan,action: OtLookupKind(kind),flags: OtLookupFlags): OtLookupInfo(kind)
fun ot_lookups_validate{kind:int}(b: !Buf,info: OtLayoutInfo,domain: OtLayoutDomain(kind),caps: OtGdefCapabilities): Option_vt(OtError)
