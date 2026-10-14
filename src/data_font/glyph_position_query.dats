#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position.sats"
staload "data_font/glyph_position_work.sats"
implement glyph_position_scale(p) = case+ p of
  | PositionAccumulating(run,scale) => scale | PositionFrozen(run,scale,d) => scale
implement glyph_position_meta(p) = case+ p of
  | PositionAccumulating(run,scale) => glyph_run_meta(run) | PositionFrozen(run,scale,d) => glyph_run_meta(run)
implement glyph_position_query(p,node) = case+ p of
  | PositionAccumulating(run,scale) => glyph_run_query(run,node) | PositionFrozen(run,scale,d) => glyph_run_query(run,node)
implement glyph_position_dispose(p) = case+ p of
  | ~PositionAccumulating(run,scale) => glyph_run_dispose(run) | ~PositionFrozen(run,scale,d) => glyph_run_dispose(run)
implement glyph_position_direction(p) = let val+ PositionFrozen(run,scale,d)=p in d end
