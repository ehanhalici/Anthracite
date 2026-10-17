#include "data_font/glyph/position/glyph_position_lookup_graph_internal.hats"
fun walk{n,k,r:nat} .<r>. (left: int(r),m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  selection: GlyphSelection,parents: !GlyphPositionBases(k),node: int,previous: int): GlyphPositionStatus =
  if ieq(node,~1) then PositionReady() else if left = 0 then PositionReference()
  else if not(glyph_run_node(s,meta,node)) then PositionReference() else let
    val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
    val ()=glyph_position_bases_set(parents,node,previous)
    val keep=not(glyph_position_is_mark(m,core)) andalso glyph_pass_selected(selection,core.mask)
  in walk(left-1,m,s,meta,selection,parents,links.next,if keep then node else previous) end
implement glyph_position_lookup_graph_parents(m,s,meta,selection,parents) =
  walk(airlock_nat(meta.live),m,s,meta,selection,parents,meta.head,~1)
