staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_anchor_cache_types.sats"
staload "data_font/opentype/position/gpos_mark_shared_types.sats"
datatype GposMarkMatrixDomain(int) = MarkToBase(4) | MarkToMark(6)
typedef GposMarkMatrixInfo = GposMarkInfo
datavtype GposMarkMatrixHeader = MarkMatrixHeaderAccepted of GposMarkMatrixInfo | MarkMatrixHeaderRejected of OtError
datavtype GposMarkMatrix(kind:int) =
  | {m,t:nat} GposMarkMatrix(kind) of (GposMarkMatrixDomain(kind),GposMarkMatrixInfo,OtAnchorCache(m,m),OtAnchorCache(t,t))
datavtype GposMarkMatrixRead(kind:int) =
  | MarkMatrixAccepted(kind) of GposMarkMatrix(kind) | MarkMatrixRejected(kind) of OtError
typedef GposMarkMatrixView = @{matched=bool,mark=OtAnchorSlot,target=OtAnchorSlot,markClass=int}
