staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/substitution/gsub_ligature_types.sats"
fun gsub_ligatures_parse(b: !Buf,span: OtSpan,glyphs: int): GsubLigaturesRead
(* Input is logical-order uint32 glyph IDs, with contextual lookup flags already
   applied by the caller. The current/first input glyph is never filtered out.
   Rule order is font preference order; the first complete match wins. *)
fun gsub_ligatures_match(b: !Buf,table: !GsubLigatures,input: !Buf,count: int,start: int): GsubLigatureResult
fun gsub_ligatures_query(b: !Buf,table: !GsubLigatures,input: !Buf,count: int,start: int,remaining: &int >> _): GsubLigatureMatch
fun gsub_ligatures_dispose(table: GsubLigatures): void
