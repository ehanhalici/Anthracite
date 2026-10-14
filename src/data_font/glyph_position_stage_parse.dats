#include "data_font/glyph_position_lookup_graph_internal.hats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_layout_parse.sats"
staload "data_font/ot_layout_plan.sats"
staload "data_font/ot_position_graph.sats"
staload "data_font/glyph_position_stage_types.sats"
staload "data_font/glyph_position_stage_work.sats"
staload "data_font/glyph_position_stage.sats"
fun fill{n:nat} .<n>. (left: int(n),p: !OtStagePlan(2),ids: !Buf,index: int,total: int): bool =
  if left = 0 then true else let val id=ot_plan_lookup(p,index) in
    if ilt(id,0) orelse ige(id,total) then false else let val ()=buf_set32(ids,index,id)
    in fill(left-1,p,ids,iadd(index,1),total) end end
fun selected(t: !OtLayoutTable(2,0),p: !OtStagePlan(2),g: OtPositionGraph,selection: GlyphSelection): GlyphPositionStageRead = let
  val count=ot_plan_lookup_count(p) val ids=buf_make(imul(count,4)) val info=ot_layout_info(t)
  val valid=fill(airlock_nat(count),p,ids,0,info.lookupCount)
in if valid then PositionStageAccepted(GlyphPositionStage(g,ids,selection,count)) else let
  val ()=buf_free(ids) and ()=ot_position_graph_dispose(g)
in PositionStageRejected(ot_error(OtReference(),info.span)) end end
implement glyph_position_stage_parse(b,t,p,m,selection) = let val info=glyph_metadata_info(m)
in case+ ot_position_graph_parse(b,t,info.font,info.glyphs) of
  | ~PositionGraphRejected(e) => PositionStageRejected(e)
  | ~PositionGraphAccepted(g) => selected(t,p,g,selection) end
