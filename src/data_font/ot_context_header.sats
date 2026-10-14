staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_context_types.sats"
datavtype OtContextHeaderRead = ContextHeaderAccepted of OtContextInfo | ContextHeaderRejected of OtError
fun ot_context_info(span: OtSpan,mode: OtContextMode,encoding: OtContextEncoding,
  header: int,count: int,floor: int,glyphs: int,lookups: int): OtContextInfo
fun ot_context_header_parse(b: !Buf,span: OtSpan,glyphs: int,lookups: int,mode: OtContextMode): OtContextHeaderRead
fun ot_context_classes(b: !Buf,info: OtContextInfo): OtContextHeaderRead
fun ot_context_direct(b: !Buf,span: OtSpan,glyphs: int,lookups: int,mode: OtContextMode): OtContextHeaderRead
