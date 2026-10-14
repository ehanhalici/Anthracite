staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_mark_matrix_types.sats"
fun gpos_mark_matrix_parse{kind:int}(b: !Buf,span: OtSpan,glyphs: int,domain: GposMarkMatrixDomain(kind)): GposMarkMatrixRead(kind)
(* The scheduler chooses the preceding base/mark and associates source clusters.
   This reader only resolves the font's corresponding attachment anchors. *)
fun gpos_mark_matrix_query{kind:int}(b: !Buf,table: !GposMarkMatrix(kind),mark: int,target: int): GposMarkMatrixView
fun gpos_mark_matrix_dispose{kind:int}(table: GposMarkMatrix(kind)): void
fun gpos_mark_matrix_glyphs{kind:int}(table: !GposMarkMatrix(kind)): int
fun gpos_mark_matrix_target{kind:int}(b: !Buf,table: !GposMarkMatrix(kind),glyph: int): bool
