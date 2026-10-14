staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gsub_ligature_types.sats"
fun gsub_ligature_set(b: !Buf,info: GsubLigatureInfo,index: int): OtChild
fun gsub_ligature_rule(b: !Buf,set: OtSpan,index: int): OtChild
fun gsub_ligatures_validate(b: !Buf,info: GsubLigatureInfo,remaining: &int >> _): Option_vt(OtError)
fun gsub_ligature_maximum(b: !Buf,info: GsubLigatureInfo): int
