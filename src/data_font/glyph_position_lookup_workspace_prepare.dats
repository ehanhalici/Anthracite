#include "data_font/glyph_position_lookup_graph_internal.hats"
staload "data_font/glyph_position_lookup_workspace_types.sats"
staload "data_font/glyph_position_lookup_workspace.sats"
implement glyph_position_lookup_workspace_prepare(b,g,m,s,meta,selection,workspace) = let
  val+ GlyphPositionLookupWorkspace(c,parents,stack,map,active)=workspace
  val ()=glyph_position_cache_copy(s,c,meta.used)
  val status=glyph_position_lookup_graph_parents(m,s,meta,selection,parents)
in if glyph_position_ready(status) then glyph_position_lookup_graph_map_build(b,g,m,s,meta,map) else status end
