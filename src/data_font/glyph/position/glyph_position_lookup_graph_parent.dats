#include "data_font/glyph/position/glyph_position_lookup_graph_internal.hats"
staload "data_font/opentype/position/gpos_mark_matrix.sats"
staload "data_font/opentype/position/gpos_mark_ligature.sats"
fun accepted{n:nat}(b: !Buf,p: !OtPositionPayload,m: !GlyphMetadata,s: !GlyphStorage(n),core: GlyphCore,previous: int): bool = case+ p of
  | PositionPayloadBase(t) => glyph_position_mark_base_accept(m,s,core,previous) orelse gpos_mark_matrix_target(b,t,core.glyph)
  | PositionPayloadLigature(t) => not(core.multiplied) orelse ieq(core.component,0) orelse igt(gpos_mark_ligature_components(b,t,core.glyph),0)
  | PositionPayloadVacant() => false | PositionPayloadSingle(t) => false
  | PositionPayloadPair(t) => false | PositionPayloadCursive(t) => false | PositionPayloadMark(t) => false
fun walk{n,k,r:nat} .<r>. (left: int(r),b: !Buf,p: !OtPositionPayload,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  node: int,parents: !GlyphPositionBases(k),remaining: &int >> _): GlyphMarkParent =
  if ieq(node,~1) then @{status=PositionReady(),node= ~1}
  else if left = 0 then @{status=PositionReference(),node= ~1}
  else if not(glyph_run_node(s,meta,node)) then @{status=PositionReference(),node= ~1}
  else if ile(remaining,0) then @{status=PositionCapacity(),node= ~1} else let
    val ()=remaining := isub(remaining,1)
    val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
  in if accepted(b,p,m,s,core,links.previous) then @{status=PositionReady(),node=node}
    else walk(left-1,b,p,m,s,meta,glyph_position_bases_get(parents,node),parents,remaining) end
fun required(p: !OtPositionPayload): bool = case+ p of | PositionPayloadBase(t) => true | PositionPayloadLigature(t) => true
  | PositionPayloadVacant() => false | PositionPayloadSingle(t) => false | PositionPayloadPair(t) => false
  | PositionPayloadCursive(t) => false | PositionPayloadMark(t) => false
implement glyph_position_lookup_graph_parent(b,p,m,s,meta,node,parents,remaining) =
  if not(required(p)) then @{status=PositionReady(),node= ~1}
  else walk(airlock_nat(meta.live),b,p,m,s,meta,glyph_position_bases_get(parents,node),parents,remaining)
