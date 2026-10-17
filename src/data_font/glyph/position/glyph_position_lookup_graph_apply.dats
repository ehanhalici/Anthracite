#include "data_font/glyph/position/glyph_position_lookup_graph_internal.hats"
fun execute(b: !Buf,g: !OtPositionGraph,m: !GlyphMetadata,p: GlyphPositioned(0),lookup: int,
  selection: GlyphSelection,d: GlyphPositionDirection,w: !GlyphContextWindow,capacity: GlyphPositionLookupGraphCapacity): GlyphPositionResult = let
  val+ ~PositionAccumulating(run,scale)=p val+ ~GlyphRun(phase,meta,s)=run
  var matches: int=0
  val status=glyph_position_lookup_graph_scratch(b,g,m,s,meta,scale,selection,d,lookup,w,capacity,matches)
in GlyphPositionResult(PositionAccumulating(GlyphRun(phase,meta,s),scale),status,
  if glyph_position_ready(status) then meta.live else 0,if glyph_position_ready(status) then matches else 0) end
fun allocated(b: !Buf,g: !OtPositionGraph,m: !GlyphMetadata,p: GlyphPositioned(0),lookup: int,
  selection: GlyphSelection,d: GlyphPositionDirection,capacity: GlyphPositionLookupGraphCapacity): GlyphPositionResult = let
  val+ OtPositionGraph(font,glyphs,limits,entries)=g
in case+ glyph_window_make(limits) of
  | ~WindowRejected(status) => GlyphPositionResult(p,glyph_position_lookup_graph_window_status(status),0,0)
  | ~WindowAllocated(w) => let val result=execute(b,g,m,p,lookup,selection,d,w,capacity)
    val ()=glyph_window_dispose(w) in result end end
fun checked(b: !Buf,g: !OtPositionGraph,m: !GlyphMetadata,p: GlyphPositioned(0),lookup: int,
  selection: GlyphSelection,d: GlyphPositionDirection): GlyphPositionResult = let
  val+ PositionAccumulating(run,scale)=p val meta=glyph_run_meta(run)
  val+ OtPositionGraph(font,glyphs,limits,entries)=g val+ OtPositionGraphEntries(pf,gc | rows,count,filled)=entries
  val capacity=glyph_position_lookup_graph_capacity(count,meta,limits)
in if glyph_position_ready(capacity.status) then allocated(b,g,m,p,lookup,selection,d,capacity)
  else GlyphPositionResult(p,capacity.status,0,0) end
implement glyph_position_lookup_graph_lookup(b,g,m,p,lookup,selection,d) = let val+ PositionAccumulating(run,scale)=p
  val status=glyph_position_lookup_graph_check(g,m,glyph_run_meta(run),lookup)
in if glyph_position_ready(status) then checked(b,g,m,p,lookup,selection,d) else GlyphPositionResult(p,status,0,0) end
