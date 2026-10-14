staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/gpos_mark_shared_types.sats"
typedef GposLigatureGroup = @{span=OtSpan,components=int,start=int,floor=int}
datavtype GposLigatureGroups(int,int) =
  | {n,i:nat | i <= n}{l:addr} GposLigatureGroups(n,i) of (arrayptr(GposLigatureGroup,l,n),int(n),int(i))
datavtype GposLigatureGroupsRead =
  | {n:nat} LigatureGroupsAccepted of (GposLigatureGroups(n,n),int) | LigatureGroupsRejected of OtError
datavtype GposLigatureAnchorPartial(n:int) =
  | {i:nat | i <= n} LigatureAnchorsPartial(n) of OtAnchorCache(n,i) | LigatureAnchorsRejected(n) of OtError
datavtype GposMarkLigature =
  | {m,n,t:nat} GposMarkLigature of (GposMarkInfo,OtAnchorCache(m,m),GposLigatureGroups(n,n),OtAnchorCache(t,t))
datavtype GposMarkLigatureRead = MarkLigatureAccepted of GposMarkLigature | MarkLigatureRejected of OtError
typedef GposMarkLigatureView = @{matched=bool,mark=OtAnchorSlot,target=OtAnchorSlot,markClass=int,components=int}
