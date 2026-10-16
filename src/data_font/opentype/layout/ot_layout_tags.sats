staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
fun ot_tag_of_string(text: string): Option_vt(OtTag)
fun ot_tag_valid(code: int): bool
fun ot_tag_at(b: !Buf,span: OtSpan,relative: int): OtTag
fun ot_tag_default(): OtTag
