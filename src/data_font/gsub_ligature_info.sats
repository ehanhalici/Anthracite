staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gsub_ligature_types.sats"
(* Validated immutable descriptor. Native lookup arrays use this query without
   constructing a heap-allocated linear table wrapper per candidate glyph. *)
fun gsub_ligature_info_query(b: !Buf,info: GsubLigatureInfo,input: !Buf,count: int,start: int,remaining: &int >> _): GsubLigatureMatch
fun gsub_ligature_info_input(b: !Buf,info: GsubLigatureInfo,glyph: int,remaining: &int >> _): GsubLigatureInputBound
