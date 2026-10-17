#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype/position_lookup/ot_position_graph_types.sats"
fun illegal(xs: OtPositionGraphEntries(2,1)): OtPositionGraph =
  OtPositionGraph(3,128,@{back=0,input=1,look=0},xs)
