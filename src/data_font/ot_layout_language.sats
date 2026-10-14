staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
fun ot_language_info(b: !Buf,span: OtSpan): OtLanguageInfo
fun ot_language_validate(b: !Buf,span: OtSpan,features: int): Option_vt(OtError)
fun ot_scripts_validate(b: !Buf,info: OtLayoutInfo): Option_vt(OtError)
fun ot_script_select(b: !Buf,info: OtLayoutInfo,tag: OtTag): OtChild
fun ot_language_default(b: !Buf,script: OtChild): OtChild
fun ot_language_named(b: !Buf,script: OtChild,tag: OtTag): OtChild
