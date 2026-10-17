staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
staload "data_font/opentype/position/gpos_value_cache_types.sats"
fun ot_value_cache_capacity(count: int): bool
fun ot_value_cache_make{n:nat}(count: int(n)): OtValueCache(n,0)
fun ot_value_cache_count{n,i:nat}(cache: !OtValueCache(n,i)): int(n)
fun ot_value_cache_filled{n,i:nat}(cache: !OtValueCache(n,i)): int(i)
fun ot_value_cache_append{n,i:nat | i < n}(cache: OtValueCache(n,i),value: OtValueInfo): OtValueCache(n,i+1)
fun ot_value_cache_get{n:nat}(cache: !OtValueCache(n,n),index: int): OtValueInfo
fun ot_value_cache_dispose{n,i:nat}(cache: OtValueCache(n,i)): void
fun ot_value_cache_read(b: !Buf,span: OtSpan,at: int,count: int,format: OtValueFormat,floor: int): OtValueCacheRead
