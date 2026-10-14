staload "mem.sats"
staload "data_font/opentype_types.sats"
(* Native flat descriptors, not serialized semantic tags. The filled prefix is
   a type index; a partially initialized cache cannot be queried. *)
datavtype OtCoverageCache(int,int) =
  | {n:nat}{i:nat | i <= n}{l:addr} OtCoverageCache(n,i) of
      (arrayptr(OtCoverageInfo,l,n),int(n),int(i))
datavtype OtCoverageCacheRead =
  | {n:nat} CoverageCacheAccepted of OtCoverageCache(n,n)
  | CoverageCacheRejected of OtError
