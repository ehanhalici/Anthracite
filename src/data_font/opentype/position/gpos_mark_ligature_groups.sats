staload "mem.sats"
staload "data_font/opentype/position/gpos_mark_shared_types.sats"
staload "data_font/opentype/position/gpos_mark_ligature_types.sats"
fun gpos_ligature_groups_make{n:nat}(count: int(n)): GposLigatureGroups(n,0)
fun gpos_ligature_groups_count{n,i:nat}(groups: !GposLigatureGroups(n,i)): int(n)
fun gpos_ligature_groups_filled{n,i:nat}(groups: !GposLigatureGroups(n,i)): int(i)
fun gpos_ligature_groups_append{n,i:nat | i < n}(groups: GposLigatureGroups(n,i),value: GposLigatureGroup): GposLigatureGroups(n,i+1)
fun gpos_ligature_groups_get{n:nat}(groups: !GposLigatureGroups(n,n),index: int): GposLigatureGroup
fun gpos_ligature_groups_dispose{n,i:nat}(groups: GposLigatureGroups(n,i)): void
fun gpos_ligature_groups_read(b: !Buf,info: GposMarkInfo): GposLigatureGroupsRead
