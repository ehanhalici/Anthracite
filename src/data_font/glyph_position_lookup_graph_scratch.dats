#include "data_font/glyph_position_lookup_graph_internal.hats"
staload "data_font/glyph_position_lookup_workspace_types.sats"
staload "data_font/glyph_position_lookup_workspace.sats"
implement glyph_position_lookup_graph_scratch(b,g,m,s,meta,scale,selection,d,lookup,w,capacity,matches) = let
  val+ OtPositionGraph(font,glyphs,limits,entries)=g val+ OtPositionGraphEntries(pf,gc | rows,count,filled)=entries
  val workspace=glyph_position_lookup_workspace_make(airlock_nat(meta.used),count,capacity)
  var remaining: int=isub(MAX_REC_FUEL,imul(meta.live,iadd(count,1)))
  val prepared=glyph_position_lookup_workspace_prepare(b,g,m,s,meta,selection,workspace)
  val status=if glyph_position_ready(prepared) then
    glyph_position_lookup_workspace_walk(b,g,m,s,meta,scale,selection,d,lookup,w,workspace,remaining,matches) else prepared
  val ()=if glyph_position_ready(status) then glyph_position_lookup_workspace_commit(workspace,s,meta.used) else ()
  val ()=glyph_position_lookup_workspace_dispose(workspace)
in status end
