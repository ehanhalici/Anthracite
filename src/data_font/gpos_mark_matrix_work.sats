staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_mark_matrix_types.sats"
fun gpos_mark_matrix_header(b: !Buf,span: OtSpan,glyphs: int): GposMarkMatrixHeader
fun gpos_mark_matrix_validate(info: GposMarkMatrixInfo): GposMarkMatrixHeader
