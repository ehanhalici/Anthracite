staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
datatype OtAnchorPresence = AnchorOptional | AnchorRequired
datatype OtAnchorSlotKind = AnchorMissing | AnchorPresent
typedef OtAnchorSlot = @{kind=OtAnchorSlotKind,anchor=OtAnchorInfo}
datavtype OtAnchorSlotRead = AnchorSlotAccepted of OtAnchorSlot | AnchorSlotRejected of OtError
datavtype OtAnchorCache(int,int) =
  | {n,i:nat | i <= n}{l:addr} OtAnchorCache(n,i) of (arrayptr(OtAnchorSlot,l,n),int(n),int(i))
datavtype OtAnchorCacheRead =
  | {n:nat} AnchorCacheAccepted of OtAnchorCache(n,n) | AnchorCacheRejected of OtError
