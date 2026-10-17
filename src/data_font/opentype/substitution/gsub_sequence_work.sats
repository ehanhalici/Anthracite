staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/substitution/gsub_sequence_types.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
fun gsub_sequences_parse_work{kind:int}(b: !Buf,span: OtSpan,glyphs: int,
  domain: GsubSequenceDomain(kind),remaining: &int >> _): GsubSequencesRead(kind)
fun gsub_sequences_query_info(b: !Buf,info: GsubSequenceInfo,glyph: int): GsubSequenceView
fun gsub_alternate_select_info(b: !Buf,info: GsubSequenceInfo,glyph: int,choice: int): GsubSingleResult
fun gsub_sequence_child(b: !Buf,info: GsubSequenceInfo,index: int): OtChild
fun gsub_sequences_validate{kind:int}(b: !Buf,info: GsubSequenceInfo,
  domain: GsubSequenceDomain(kind),remaining: &int >> _): Option_vt(OtError)
