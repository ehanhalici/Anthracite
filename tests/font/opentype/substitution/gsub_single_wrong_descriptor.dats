#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/opentype/substitution/gsub_single.sats"
fun cannot_query_topology(b: !Buf,table: !OtLayoutTable(1,0)): GsubSingleResult =
  gsub_single_query(b,table,0)
