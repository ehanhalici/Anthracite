#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/ot_ligation_lookup_types.sats"
staload "data_font/ot_ligation_lookup_work.sats"
fun illegal(b: !Buf,t: !OtLigationTables(2,1),input: !Buf,remaining: &int >> _): GsubLigatureMatch =
  ot_ligation_tables_query(b,t,input,2,0,remaining)
