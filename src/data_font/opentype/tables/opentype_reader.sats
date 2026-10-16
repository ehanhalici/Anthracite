staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
fun ot_span_valid(b: !Buf,span: OtSpan): bool
(* maxp.numGlyphs is uint16; valid glyph IDs stop at numGlyphs - 1. *)
fun ot_glyph_domain_valid(glyphs: int): bool
fun ot_rows_fit(span: OtSpan,header: int,count: int,stride: int): bool
fun ot_u16(b: !Buf,span: OtSpan,relative: int): int
fun ot_range(b: !Buf,span: OtSpan,index: int): OtRange
fun ot_encoding_of(code: int): Option_vt(OtEncoding)
fun ot_error(reason: OtErrorReason,span: OtSpan): OtError
fun ot_u32(b: !Buf,span: OtSpan,relative: int): int
fun ot_optional_child(parent: OtSpan,relative: int,floor: int): OtChild
fun ot_child_valid(child: OtChild): bool
