#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_substitution_graph_types.sats"
staload "data_font/ot_substitution_graph.sats"
fun illegal(b: !Buf,table: !OtLayoutTable(2,0)): OtSubstitutionGraphRead =
  ot_substitution_graph_parse(b,table,3,128)
