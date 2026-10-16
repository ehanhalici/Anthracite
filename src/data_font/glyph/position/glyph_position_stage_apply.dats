#include "data_font/glyph/position/glyph_position_lookup_graph_internal.hats"
staload "data_font/glyph/position/glyph_position_lookup_workspace_types.sats"
staload "data_font/glyph/position/glyph_position_lookup_workspace.sats"
staload "data_font/glyph/position/glyph_position_stage_types.sats"
staload "data_font/glyph/position/glyph_position_stage_work.sats"
staload "data_font/glyph/position/glyph_position_stage.sats"
fun execute(b: !Buf,stage: !GlyphPositionStage,m: !GlyphMetadata,p: GlyphPositioned(0),d: GlyphPositionDirection,
  w: !GlyphContextWindow,capacity: GlyphPositionLookupGraphCapacity): GlyphPositionStageResult = let
  val+ ~PositionAccumulating(run,scale)=p val+ ~GlyphRun(phase,meta,s)=run
  val+ GlyphPositionStage(g,ids,selection,count)=stage
  val+ OtPositionGraph(font,glyphs,limits,entries)=g val+ OtPositionGraphEntries(pf,gc | rows,total,filled)=entries
  val workspace=glyph_position_lookup_workspace_make(airlock_nat(meta.used),total,capacity)
  var applied: int=0 and matches: int=0 and remaining: int=isub(MAX_REC_FUEL,imul(meta.live,iadd(total,1)))
  val prepared=glyph_position_lookup_workspace_prepare(b,g,m,s,meta,selection,workspace)
  val status=if glyph_position_ready(prepared) then
    glyph_position_stage_walk(b,stage,m,s,meta,scale,d,w,workspace,remaining,applied,matches) else prepared
  val ()=if glyph_position_ready(status) then glyph_position_lookup_workspace_commit(workspace,s,meta.used) else ()
  val ()=glyph_position_lookup_workspace_dispose(workspace)
in PositionStageResult(PositionAccumulating(GlyphRun(phase,meta,s),scale),status,
  if glyph_position_ready(status) then applied else 0,if glyph_position_ready(status) then matches else 0) end
fun allocated(b: !Buf,stage: !GlyphPositionStage,m: !GlyphMetadata,p: GlyphPositioned(0),d: GlyphPositionDirection,
  capacity: GlyphPositionLookupGraphCapacity): GlyphPositionStageResult = let
  val+ GlyphPositionStage(g,ids,selection,count)=stage val+ OtPositionGraph(font,glyphs,limits,entries)=g
in case+ glyph_window_make(limits) of
  | ~WindowRejected(status) => PositionStageResult(p,glyph_position_lookup_graph_window_status(status),0,0)
  | ~WindowAllocated(w) => let val result=execute(b,stage,m,p,d,w,capacity)
    val ()=glyph_window_dispose(w) in result end end
fun checked(b: !Buf,stage: !GlyphPositionStage,m: !GlyphMetadata,p: GlyphPositioned(0),d: GlyphPositionDirection): GlyphPositionStageResult = let
  val+ PositionAccumulating(run,scale)=p val+ GlyphPositionStage(g,ids,selection,count)=stage
  val+ OtPositionGraph(font,glyphs,limits,entries)=g val+ OtPositionGraphEntries(pf,gc | rows,total,filled)=entries
  val capacity=glyph_position_lookup_graph_capacity(total,glyph_run_meta(run),limits)
in if glyph_position_ready(capacity.status) then allocated(b,stage,m,p,d,capacity) else PositionStageResult(p,capacity.status,0,0) end
implement glyph_position_stage_apply(b,stage,m,p,d) = let val+ PositionAccumulating(run,scale)=p
  val status=glyph_position_stage_check(stage,m,glyph_run_meta(run))
in if glyph_position_ready(status) then checked(b,stage,m,p,d) else PositionStageResult(p,status,0,0) end
