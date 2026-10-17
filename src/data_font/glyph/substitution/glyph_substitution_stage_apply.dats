#include "data_font/glyph/substitution/glyph_substitution_stage_internal.hats"
typedef StageCounts = @{status=GlyphPassStatus,applied=int,matches=int}
fun walk{n:nat} .<n>. (left: int(n),b: !Buf,stage: !GlyphSubstitutionStage,m: !GlyphMetadata,
  run: &GlyphRun(1) >> GlyphRun(1),w: &GlyphSubstitutionWorkspace >> GlyphSubstitutionWorkspace,
  index: int,applied: int,matches: int,remaining: &int >> int): StageCounts =
  if left = 0 then @{status=GlyphPassApplied(),applied=applied,matches=matches} else let
    val+ GlyphSubstitutionStage(g,ids,options,count)=stage
    val result=glyph_substitution_walk(b,g,m,run,buf_get32(ids,index),options,w,remaining)
  in case+ result.status of | GlyphPassApplied() => walk(left-1,b,stage,m,run,w,iadd(index,1),iadd(applied,1),iadd(matches,result.matches),remaining)
    | GlyphPassDomain() => @{status=result.status,applied=0,matches=0}
    | GlyphPassReference() => @{status=result.status,applied=0,matches=0}
    | GlyphPassCapacity() => @{status=result.status,applied=0,matches=0} end
fun finish(source: GlyphRun(1),run: GlyphRun(1),result: StageCounts): GlyphSubstitutionStageResult =
  if glyph_substitution_ready(result.status) then let val ()=glyph_run_dispose(source)
    in SubStageResult(run,result.status,result.applied,result.matches) end else let val ()=glyph_run_dispose(run)
    in SubStageResult(source,result.status,0,0) end
fun transaction(b: !Buf,stage: !GlyphSubstitutionStage,m: !GlyphMetadata,source: GlyphRun(1),
  workspace: GlyphSubstitutionWorkspace,remaining: &int >> int): GlyphSubstitutionStageResult = let
  val+ GlyphSubstitutionStage(g,ids,options,count)=stage
  var run: GlyphRun(1)=glyph_run_clone(source) and w: GlyphSubstitutionWorkspace=workspace
  val result=walk(airlock_nat(count),b,stage,m,run,w,0,0,0,remaining)
  val ()=glyph_substitution_workspace_dispose(w)
in finish(source,run,result) end
fun allocated(b: !Buf,stage: !GlyphSubstitutionStage,m: !GlyphMetadata,run: GlyphRun(1),
  remaining: &int >> int): GlyphSubstitutionStageResult = let
  val+ GlyphSubstitutionStage(g,ids,options,count)=stage
  val+ OtSubstitutionGraph(font,glyphs,limits,entries)=g
  val capacity=glyph_substitution_capacity(run,limits)
in case+ glyph_substitution_workspace_make(limits,capacity) of | ~SubWorkspaceRejected(e) => SubStageResult(run,e,0,0)
  | ~SubWorkspaceAccepted(w) => transaction(b,stage,m,run,w,remaining) end
implement glyph_substitution_stage_budget(b,stage,m,run,remaining) = let
  val+ GlyphSubstitutionStage(g,ids,options,count)=stage
  val status=glyph_substitution_validate_graph(g,m,run)
in if not(glyph_substitution_ready(status)) then SubStageResult(run,status,0,0)
  else if ieq(count,0) then SubStageResult(run,GlyphPassApplied(),0,0) else allocated(b,stage,m,run,remaining) end
implement glyph_substitution_stage_apply(b,stage,m,run) = let var remaining: int=MAX_REC_FUEL
in glyph_substitution_stage_budget(b,stage,m,run,remaining) end
