staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_value_cache_types.sats"
staload "data_font/gpos_pair_types.sats"
fun gpos_pair_formats(b: !Buf,s: OtSpan): GposPairFormatRead
fun gpos_pair_coverage(b: !Buf,s: OtSpan,floor: int,glyphs: int): OtCoverageRead
fun gpos_pair_empty_class(): OtClassInfo
fun gpos_pair_info(s: OtSpan,c: OtCoverageInfo,f: GposPairFormat,glyphs: int): GposPairInfo
fun gpos_pair_explicit(b: !Buf,s: OtSpan,glyphs: int,f: GposPairFormat): GposPairRead
fun gpos_pair_classes(b: !Buf,s: OtSpan,glyphs: int,f: GposPairFormat): GposPairRead
fun gpos_pair_set_glyphs(b: !Buf,s: OtSpan,count: int,stride: int,glyphs: int): bool
fun gpos_pair_set_values{n,i:nat | i <= n}(b: !Buf,set: GposPairSet,f: GposPairFormat,
  cache: OtValueCache(n,i)): GposPairPartial(n)
fun gpos_pair_set_ingest{n,m:nat}(b: !Buf,info: GposPairInfo,sets: GposPairSets(n,n),count: int(m)): GposPairRead
fun gpos_pair_matrix(b: !Buf,info: GposPairInfo): GposPairRead
fun gpos_pair_missing(): GposPairView
fun gpos_pair_view{n:nat}(cache: !OtValueCache(n,n),index: int,progress: GposPairProgress): GposPairView
