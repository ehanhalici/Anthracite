staload "data_font/resources/font.sats"
staload "data_font/atlas/private/font_cache_types.sats"
fun font_cache_kind_code(kind: FontCacheKind): int
fun font_cache_hash(key: FontCacheKey): int
fun font_cache_matches(f: !Font,slot: int,key: FontCacheKey): bool
fun font_cache_read(f: !Font,slot: int,g: &gmet >> _): void
fun font_cache_write(f: !Font,slot: int,key: FontCacheKey,g: &gmet): void
fun font_cache_find(f: !Font,key: FontCacheKey): int
