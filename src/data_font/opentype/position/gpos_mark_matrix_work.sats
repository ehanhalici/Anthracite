staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_mark_matrix_types.sats"
fun gpos_mark_matrix_header(b: !Buf,span: OtSpan,glyphs: int): GposMarkMatrixHeader
fun gpos_mark_matrix_validate(info: GposMarkMatrixInfo): GposMarkMatrixHeader
