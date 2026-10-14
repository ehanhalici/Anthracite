staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_anchor_cache_types.sats"
fun ot_anchor_missing(): OtAnchorSlot
fun ot_anchor_cache_capacity(count: int): bool
fun ot_anchor_slot_parse(b: !Buf,parent: OtSpan,offset: int,floor: int,presence: OtAnchorPresence): OtAnchorSlotRead
fun ot_anchor_cache_make{n:nat}(count: int(n)): OtAnchorCache(n,0)
fun ot_anchor_cache_count{n,i:nat}(cache: !OtAnchorCache(n,i)): int(n)
fun ot_anchor_cache_filled{n,i:nat}(cache: !OtAnchorCache(n,i)): int(i)
fun ot_anchor_cache_append{n,i:nat | i < n}(cache: OtAnchorCache(n,i),value: OtAnchorSlot): OtAnchorCache(n,i+1)
fun ot_anchor_cache_get{n:nat}(cache: !OtAnchorCache(n,n),index: int): OtAnchorSlot
fun ot_anchor_cache_dispose{n,i:nat}(cache: OtAnchorCache(n,i)): void
(* fields is a uint32 list of Offset16 field locations. The parent base and
   immutable referenced bytes stay borrowed; absent slots are typed. *)
fun ot_anchor_cache_read(b: !Buf,parent: OtSpan,fields: !Buf,floor: int,presence: OtAnchorPresence): OtAnchorCacheRead
