staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gsub_single_types.sats"
fun gsub_single_parse(b: !Buf,span: OtSpan,glyphs: int): GsubSingleRead
(* No match leaves the input glyph unchanged, including out-of-domain queries. *)
fun gsub_single_query(b: !Buf,table: !GsubSingle,glyph: int): GsubSingleResult
fun gsub_single_dispose(table: GsubSingle): void
