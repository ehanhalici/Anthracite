#include "data_font/glyph/position/glyph_position_schedule_internal.hats"
implement glyph_position_schedule_execute(b,g,schedule,m,p,d,w,capacity) = let
  val+ ~PositionAccumulating(run,scale)=p val+ ~GlyphRun(phase,meta,s)=run
  val+ OtPositionGraph(font,glyphs,limits,entries)=g
  val+ OtPositionGraphEntries(pf,gc | rows,total,filled)=entries
  val workspace=glyph_position_lookup_workspace_make(airlock_nat(meta.used),total,capacity)
  var applied: int=0 and matches: int=0 and remaining: int=isub(MAX_REC_FUEL,imul(meta.live,iadd(total,1)))
  val prepared=glyph_position_lookup_workspace_prepare(b,g,m,s,meta,@{kind=GlyphAll(),mask=0u},workspace)
  val status=if glyph_position_ready(prepared) then
    glyph_position_schedule_walk(b,g,schedule,m,s,meta,scale,d,w,workspace,remaining,applied,matches) else prepared
  val ()=if glyph_position_ready(status) then glyph_position_lookup_workspace_commit(workspace,s,meta.used) else ()
  val ()=glyph_position_lookup_workspace_dispose(workspace)
in PositionStageResult(PositionAccumulating(GlyphRun(phase,meta,s),scale),status,
  if glyph_position_ready(status) then applied else 0,if glyph_position_ready(status) then matches else 0) end
