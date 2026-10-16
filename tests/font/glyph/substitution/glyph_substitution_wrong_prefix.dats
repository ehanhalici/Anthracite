#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/opentype/substitution_graph/ot_substitution_graph_types.sats"
fun illegal(t: OtSubstitutionGraphEntries(2,1)): OtSubstitutionGraph =
  OtSubstitutionGraph(3,128,@{back=0,input=1,look=0},t)
