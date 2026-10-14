staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gsub_single_types.sats"
fun gsub_delta_add(glyph: int,delta: int): int
fun gsub_delta_valid(b: !Buf,coverage: OtCoverageInfo,delta: int,glyphs: int): bool
fun gsub_array_valid(b: !Buf,span: OtSpan,count: int,glyphs: int): bool
(* Internal query for a payload-validated flat descriptor retained by a cache. *)
fun gsub_single_query_info(b: !Buf,info: GsubSingleInfo,glyph: int): GsubSingleResult
