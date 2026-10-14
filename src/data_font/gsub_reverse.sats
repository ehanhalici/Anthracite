staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/gsub_reverse_types.sats"
fun gsub_reverse_parse(b: !Buf,span: OtSpan,glyphs: int): GsubReverseRead
(* Logical uint32 input with lookup-context filtering already applied. A run
   scheduler must visit candidates from end to start for lookup type 8. *)
fun gsub_reverse_match(b: !Buf,table: !GsubReverse,input: !Buf,count: int,start: int): GsubSingleResult
fun gsub_reverse_dispose(table: GsubReverse): void
