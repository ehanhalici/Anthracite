#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "data_font/opentype/position/gpos_mark_ligature_types.sats"
staload "data_font/opentype/position/gpos_mark_ligature_groups.sats"
extern fun unfinished_ligature_group(groups: !GposLigatureGroups(2,1)): GposLigatureGroup
implement unfinished_ligature_group(groups) = gpos_ligature_groups_get(groups,0)
