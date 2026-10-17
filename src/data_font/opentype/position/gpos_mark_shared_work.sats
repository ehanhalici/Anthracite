staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_mark_shared_types.sats"
fun gpos_mark_coverage(b: !Buf,s: OtSpan,field: int,glyphs: int): OtCoverageRead
fun gpos_mark_arrays(b: !Buf,s: OtSpan,marks: OtCoverageInfo,targets: OtCoverageInfo,glyphs: int): GposMarkHeaderRead
fun gpos_mark_records(b: !Buf,s: OtSpan,count: int,classes: int): bool
