#include "data_font/glyph/position/glyph_position_lookup_graph_internal.hats"
staload "data_font/glyph/position/glyph_position_lookup_workspace_types.sats"
staload "data_font/glyph/position/glyph_position_lookup_workspace.sats"
implement glyph_position_lookup_workspace_walk(b,g,m,s,meta,scale,selection,d,lookup,w,workspace,remaining,matches) = let
  val+ @GlyphPositionLookupWorkspace(c,parents,stack,map,active)=workspace
  val status=glyph_position_lookup_graph_walk(b,g,m,s,meta,scale,c,selection,d,lookup,parents,w,stack,map,active,remaining,matches)
  prval ()=fold@(workspace)
in status end
