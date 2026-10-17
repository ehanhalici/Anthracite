#include "data_font/glyph/substitution/glyph_substitution_stage_internal.hats"
fun fill{n:nat} .<n>. (left: int(n),plan: !OtStagePlan(1),ids: !Buf,index: int,total: int): bool =
  if left = 0 then true else let val id=ot_plan_lookup(plan,index) in
    if ilt(id,0) orelse ige(id,total) then false else let val ()=buf_set32(ids,index,id)
    in fill(left-1,plan,ids,iadd(index,1),total) end end
fun selected(t: !OtLayoutTable(1,0),plan: !OtStagePlan(1),g: OtSubstitutionGraph,
  options: GlyphSubstitutionOptions): GlyphSubstitutionStageRead = let
  val count=ot_plan_lookup_count(plan) val ids=buf_make(imul(count,4)) val info=ot_layout_info(t)
  val valid=fill(airlock_nat(count),plan,ids,0,info.lookupCount)
in if valid then SubStageAccepted(GlyphSubstitutionStage(g,ids,options,count)) else let
  val ()=buf_free(ids) and ()=ot_substitution_graph_dispose(g)
in SubStageRejected(ot_error(OtReference(),info.span)) end end
implement glyph_substitution_stage_parse(b,t,plan,m,options) = let val info=glyph_metadata_info(m)
in case+ ot_substitution_graph_parse(b,t,info.font,info.glyphs) of
  | ~SubstitutionGraphRejected(e) => SubStageRejected(e)
  | ~SubstitutionGraphAccepted(g) => selected(t,plan,g,options) end
implement glyph_substitution_stage_dispose(stage) = let val+ ~GlyphSubstitutionStage(g,ids,options,count)=stage
in ot_substitution_graph_dispose(g); buf_free(ids) end
