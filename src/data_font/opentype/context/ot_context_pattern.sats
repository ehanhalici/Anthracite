staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
fun ot_context_rule_info(b: !Buf,span: OtSpan,mode: OtContextMode): OtContextPattern
fun ot_context_rule_parse(b: !Buf,span: OtSpan,mode: OtContextMode): OtContextPatternRead
fun ot_context_rule_validate{kind:int}(b: !Buf,pattern: OtContextPattern,encoding: OtContextEncoding,
  glyphs: int,lookups: int,domain: OtLayoutDomain(kind),remaining: &int >> _): Option_vt(OtError)
