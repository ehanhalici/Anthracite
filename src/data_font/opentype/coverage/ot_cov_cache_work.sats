staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
fun ot_cov_cache_parse_child(b: !Buf,child: OtChild,glyphs: int,remaining: &int >> _): OtCoverageRead
