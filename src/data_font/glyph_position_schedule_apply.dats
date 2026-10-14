#include "data_font/glyph_position_schedule_internal.hats"
fun allocated(b: !Buf,g: !OtPositionGraph,s: !OtShapeSchedule(2),m: !GlyphMetadata,p: GlyphPositioned(0),
  d: GlyphPositionDirection,capacity: GlyphPositionLookupGraphCapacity): GlyphPositionStageResult = let
  val+ OtPositionGraph(font,glyphs,limits,entries)=g
in case+ glyph_window_make(limits) of
  | ~WindowRejected(status) => PositionStageResult(p,glyph_position_lookup_graph_window_status(status),0,0)
  | ~WindowAllocated(w) => let val result=glyph_position_schedule_execute(b,g,s,m,p,d,w,capacity)
    val ()=glyph_window_dispose(w) in result end end
fun checked(b: !Buf,g: !OtPositionGraph,s: !OtShapeSchedule(2),m: !GlyphMetadata,p: GlyphPositioned(0),
  d: GlyphPositionDirection): GlyphPositionStageResult = let
  val+ PositionAccumulating(run,scale)=p val+ OtPositionGraph(font,glyphs,limits,entries)=g
  val+ OtPositionGraphEntries(pf,gc | rows,total,filled)=entries
  val capacity=glyph_position_lookup_graph_capacity(total,glyph_run_meta(run),limits)
in if glyph_position_ready(capacity.status) then allocated(b,g,s,m,p,d,capacity)
  else PositionStageResult(p,capacity.status,0,0) end
implement glyph_position_schedule_apply(b,g,s,m,p,d) = let val+ PositionAccumulating(run,scale)=p
  val status=glyph_position_schedule_check(g,s,m,glyph_run_meta(run)) val info=ot_shape_schedule_info(s)
in if not(glyph_position_ready(status)) then PositionStageResult(p,status,0,0)
  else if ieq(info.count,0) then PositionStageResult(p,PositionReady(),0,0) else checked(b,g,s,m,p,d) end

