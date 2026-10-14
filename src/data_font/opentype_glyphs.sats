staload "mem.sats"
staload "data_font/opentype_types.sats"
(* An already bounded uint16 array, header is a byte offset, not a mode. *)
fun ot_glyph_array_valid(b: !Buf,span: OtSpan,header: int,count: int,glyphs: int): bool
