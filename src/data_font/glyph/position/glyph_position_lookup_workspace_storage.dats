#include "data_font/glyph/position/glyph_position_lookup_graph_internal.hats"
staload "data_font/glyph/position/glyph_position_lookup_workspace_types.sats"
staload "data_font/glyph/position/glyph_position_lookup_workspace.sats"
implement glyph_position_lookup_workspace_make(used,lookups,capacity) =
  GlyphPositionLookupWorkspace(glyph_position_cache_make(used),glyph_position_bases_make(used),
    glyph_position_lookup_graph_stack_make(capacity.frames),glyph_position_lookup_graph_map_make(lookups,used,capacity.cells),
    buf_make(imul(capacity.cells,4)))
implement glyph_position_lookup_workspace_dispose(workspace) = let val+ ~GlyphPositionLookupWorkspace(c,parents,stack,map,active)=workspace
  val ()=glyph_position_cache_dispose(c) and ()=glyph_position_bases_dispose(parents)
  val ()=glyph_position_lookup_graph_stack_dispose(stack) and ()=glyph_position_lookup_graph_map_dispose(map)
in buf_free(active) end
implement glyph_position_lookup_workspace_commit(workspace,s,used) = let val+ GlyphPositionLookupWorkspace(c,parents,stack,map,active)=workspace
in glyph_position_cache_commit(c,s,used) end
