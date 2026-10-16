staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/coverage/ot_cov_cache_types.sats"
fun ot_cov_cache_make{n:nat}(count: int(n)): OtCoverageCache(n,0)
fun ot_cov_cache_count{n,i:nat}(cache: !OtCoverageCache(n,i)): int(n)
fun ot_cov_cache_filled{n,i:nat}(cache: !OtCoverageCache(n,i)): int(i)
fun ot_cov_cache_append{n,i:nat | i < n}(cache: OtCoverageCache(n,i),info: OtCoverageInfo): OtCoverageCache(n,i+1)
fun ot_cov_cache_get{n:nat}(cache: !OtCoverageCache(n,n),index: int): OtCoverageInfo
fun ot_cov_cache_dispose{n,i:nat}(cache: OtCoverageCache(n,i)): void
(* Fields is a borrowed uint32 list of checked-source Offset16 field locations,
   not cloned Coverage bytes. Referenced tables are parsed exactly once. *)
fun ot_cov_cache_read(b: !Buf,span: OtSpan,fields: !Buf,floor: int,glyphs: int): OtCoverageCacheRead
