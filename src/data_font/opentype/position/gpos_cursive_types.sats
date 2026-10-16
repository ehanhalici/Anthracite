staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_anchor_cache_types.sats"
datavtype GposCursive = {n:nat} GposCursive of (OtCoverageInfo,int,OtAnchorCache(n,n))
datavtype GposCursiveRead = CursiveAccepted of GposCursive | CursiveRejected of OtError
typedef GposCursiveView = @{matched=bool,entry=OtAnchorSlot,exit=OtAnchorSlot}
typedef GposCursivePair = @{matched=bool,exit=OtAnchorSlot,entry=OtAnchorSlot}
