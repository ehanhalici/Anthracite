staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
fun ot_context_set(b: !Buf,info: OtContextInfo,index: int): OtChild
fun ot_context_rule(b: !Buf,set: OtSpan,index: int): OtChild
fun ot_context_validate{kind:int}(b: !Buf,info: OtContextInfo,domain: OtLayoutDomain(kind)): Option_vt(OtError)
fun ot_context_fields(info: OtContextInfo): Buf
