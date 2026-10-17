#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_work.sats"
staload "data_font/glyph/position/glyph_position_pair_work.sats"
staload "data_font/glyph/position/glyph_position_mark_work.sats"
staload "data_font/glyph/position/glyph_position_lookup_work.sats"
staload "data_font/glyph/position/glyph_position_lookup.sats"
fun execute(b: !Buf,t: !OtPositionLookup,m: !GlyphMetadata,p: GlyphPositioned(0),selection: GlyphSelection,d: GlyphPositionDirection): GlyphPositionResult = let
  val+ ~PositionAccumulating(run,scale)=p val+ ~GlyphRun(phase,meta,s)=run
  val c=glyph_position_cache_make(airlock_nat(meta.used))
  val ()=glyph_position_cache_copy(s,c,meta.used)
  var matches: int=0
  val status=glyph_position_lookup_walk(b,t,m,s,meta,scale,c,selection,d,matches)
  val ()=if glyph_position_ready(status) then glyph_position_cache_commit(c,s,meta.used) else ()
  val ()=glyph_position_cache_dispose(c)
in GlyphPositionResult(PositionAccumulating(GlyphRun(phase,meta,s),scale),status,
  if glyph_position_ready(status) then meta.live else 0,if glyph_position_ready(status) then matches else 0) end
implement glyph_position_lookup(b,t,m,p,selection,d) = let val+ PositionAccumulating(run,scale)=p
  val status=glyph_position_lookup_check(t,m,glyph_run_meta(run))
in if glyph_position_ready(status) then execute(b,t,m,p,selection,d) else GlyphPositionResult(p,status,0,0) end
