staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/gsub_sequence_types.sats"
fun gsub_sequences_parse{kind:int}(b: !Buf,span: OtSpan,glyphs: int,domain: GsubSequenceDomain(kind)): GsubSequencesRead(kind)
fun gsub_sequences_query{kind:int}(b: !Buf,table: !GsubSequences(kind),glyph: int): GsubSequenceView
fun gsub_sequence_glyph(b: !Buf,view: GsubSequenceView,index: int): int
(* Feature values choose a 1-based alternate, zero disables selection. *)
fun gsub_alternate_select(b: !Buf,table: !GsubSequences(3),glyph: int,choice: int): GsubSingleResult
fun gsub_sequences_dispose{kind:int}(table: GsubSequences(kind)): void
