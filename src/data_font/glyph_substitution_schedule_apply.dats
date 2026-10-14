#include "data_font/glyph_substitution_schedule_internal.hats"
fun finish(source: GlyphRun(1),run: GlyphRun(1),result: GlyphSubstitutionCounts): GlyphSubstitutionStageResult =
  if glyph_substitution_ready(result.status) then let val ()=glyph_run_dispose(source)
    in SubStageResult(run,result.status,result.visited,result.matches) end else let val ()=glyph_run_dispose(run)
    in SubStageResult(source,result.status,0,0) end
fun transaction(b: !Buf,g: !OtSubstitutionGraph,s: !OtShapeSchedule(1),m: !GlyphMetadata,source: GlyphRun(1),
  workspace: GlyphSubstitutionWorkspace,remaining: &int >> int): GlyphSubstitutionStageResult = let
  var run: GlyphRun(1)=glyph_run_clone(source) and w: GlyphSubstitutionWorkspace=workspace
  val result=glyph_substitution_schedule_walk(b,g,s,m,run,w,remaining)
  val ()=glyph_substitution_workspace_dispose(w)
in finish(source,run,result) end
fun allocated(b: !Buf,g: !OtSubstitutionGraph,s: !OtShapeSchedule(1),m: !GlyphMetadata,
  run: GlyphRun(1),remaining: &int >> int): GlyphSubstitutionStageResult = let
  val+ OtSubstitutionGraph(font,glyphs,limits,entries)=g val capacity=glyph_substitution_capacity(run,limits)
in case+ glyph_substitution_workspace_make(limits,capacity) of
  | ~SubWorkspaceRejected(e) => SubStageResult(run,e,0,0)
  | ~SubWorkspaceAccepted(w) => transaction(b,g,s,m,run,w,remaining) end
implement glyph_substitution_schedule_budget(b,g,s,m,run,remaining) = let
  val status=glyph_substitution_schedule_check(g,s,m,run) val info=ot_shape_schedule_info(s)
in if not(glyph_substitution_ready(status)) then SubStageResult(run,status,0,0)
  else if ieq(info.count,0) then SubStageResult(run,GlyphPassApplied(),0,0)
  else allocated(b,g,s,m,run,remaining) end
implement glyph_substitution_schedule_apply(b,g,s,m,run) = let var remaining: int=MAX_REC_FUEL
in glyph_substitution_schedule_budget(b,g,s,m,run,remaining) end

