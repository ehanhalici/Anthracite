staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_pair_types.sats"
fun gpos_pair_parse(b: !Buf,span: OtSpan,glyphs: int): GposPairRead
(* Logical glyph order. Lookup filtering and the next-candidate scheduler are
   the caller's job; progress distinguishes absent from present-zero value2. *)
fun gpos_pair_query(b: !Buf,table: !GposPairs,first: int,second: int): GposPairView
fun gpos_pair_glyphs(table: !GposPairs): int
fun gpos_pair_dispose(table: GposPairs): void
