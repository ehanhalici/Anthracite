#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/glyph/position/glyph_position_work.sats"
staload "data_font/glyph/position/glyph_position_graph_types.sats"
staload "data_font/glyph/position/glyph_position_graph.sats"
implement glyph_position_finish(p,d) = let
  val+ ~PositionAccumulating(run,scale)=p
  val+ ~GlyphRun(phase,meta,s)=run
  val count=airlock_nat(meta.used)
  val cache=glyph_position_cache_make(count) and graph=glyph_position_graph_make(count)
  val ()=glyph_position_cache_copy(s,cache,meta.used)
  val preflight=glyph_position_graph_prefix(s,meta,cache,graph,d)
  val status=if glyph_position_ready(preflight) then glyph_position_graph_resolve(s,meta,cache,graph,@{final=true,direction=d}) else preflight
  val ()=if glyph_position_ready(status) then glyph_position_cache_commit(cache,s,meta.used) else ()
  val ()=glyph_position_cache_dispose(cache) and ()=glyph_position_graph_dispose(graph)
in if glyph_position_ready(status) then PositionFinished(PositionFrozen(glyph_run_freeze(GlyphRun(phase,meta,s)),scale,d))
  else PositionUnfinished(PositionAccumulating(GlyphRun(phase,meta,s),scale),status) end
