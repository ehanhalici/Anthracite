#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/ot_single_lookup_types.sats"
staload "data_font/ot_single_lookup_work.sats"
extern fun unfinished_query(t: !OtSingleTables(2,1)): GsubSingleInfo
implement unfinished_query(t) = ot_single_tables_get(t,0)
