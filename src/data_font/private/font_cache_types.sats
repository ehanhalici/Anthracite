datatype FontCacheKind = CacheCodepoint | CachePrimaryGlyph | CacheFallbackGlyph
(* Face identity is the owning Font's primary/fallback slot. Face replacement
   invalidates all entries; ppem is explicit even though size changes clear it. *)
typedef FontCacheKey = @{kind=FontCacheKind,value=int,ppem=int}
