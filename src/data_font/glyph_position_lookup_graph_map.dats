#include "data_font/glyph_position_lookup_graph_internal.hats"
implement glyph_position_lookup_graph_map_make(lookups,used,cells) =
  GlyphPositionLookupGraphMap(buf_make(imul(cells,4)),buf_make(imul(cells,4)),buf_make(imul(lookups,4)),lookups,used)
implement glyph_position_lookup_graph_map_dispose(map) = let val+ ~GlyphPositionLookupGraphMap(nodes,ranks,counts,lookups,used)=map
in buf_free(nodes); buf_free(ranks); buf_free(counts) end
implement glyph_position_lookup_graph_map_node(map,lookup,node,sequence) = let
  val+ GlyphPositionLookupGraphMap(nodes,ranks,counts,lookups,used)=map
in if ilt(lookup,0) orelse ige(lookup,lookups) orelse ilt(node,0) orelse ige(node,used) orelse ilt(sequence,0) then ~1 else let
  val offset=imul(lookup,used)
  val rank=buf_get32(ranks,iadd(offset,node)) and count=buf_get32(counts,lookup)
in if ilt(rank,0) orelse ige(rank,count) orelse ige(sequence,isub(count,rank)) then ~1
  else buf_get32(nodes,iadd(offset,iadd(rank,sequence))) end end
