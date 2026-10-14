staload "mem.sats"
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/gpos_mark_shared_types.sats"
staload "data_font/gpos_mark_ligature_types.sats"
fun gpos_ligature_group_anchors{n,i:nat | i <= n}(b: !Buf,group: GposLigatureGroup,
  classes: int,cache: OtAnchorCache(n,i)): GposLigatureAnchorPartial(n)
fun gpos_ligature_anchors{m,n,t:nat}(b: !Buf,info: GposMarkInfo,marks: OtAnchorCache(m,m),
  groups: GposLigatureGroups(n,n),count: int(t)): GposMarkLigatureRead
