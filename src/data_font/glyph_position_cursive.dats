#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_cursive_types.sats"
staload "data_font/gpos_cursive.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_work.sats"
staload "data_font/glyph_position_filter.sats"
staload "data_font/glyph_position_anchor.sats"
staload "data_font/glyph_position_cursive_work.sats"
staload "data_font/glyph_position_cursive.sats"
fun execute(b: !Buf,t: !GposCursive,m: !GlyphMetadata,p: GlyphPositioned(0),
  flags: OtLookupFlags,set: int,selection: GlyphSelection,d: GlyphPositionDirection): GlyphPositionResult = let
  val+ ~PositionAccumulating(run,scale)=p val+ ~GlyphRun(phase,meta,s)=run
  val cache=glyph_position_cache_make(airlock_nat(meta.used))
  val ()=glyph_position_cache_copy(s,cache,meta.used)
  var matches: int=0
  val status=glyph_position_cursive_walk(b,t,m,s,meta,scale,flags,set,selection,d,cache,matches)
  val ()=if glyph_position_ready(status) then glyph_position_cache_commit(cache,s,meta.used) else ()
  val ()=glyph_position_cache_dispose(cache)
in GlyphPositionResult(PositionAccumulating(GlyphRun(phase,meta,s),scale),status,
  if glyph_position_ready(status) then meta.live else 0,if glyph_position_ready(status) then matches else 0) end
implement glyph_position_cursive(b,t,m,p,flags,set,selection,d) = let val+ PositionAccumulating(run,scale)=p
  val status=glyph_position_filter_check(m,glyph_run_meta(run),gpos_cursive_glyphs(t),flags,set)
in if glyph_position_ready(status) then execute(b,t,m,p,flags,set,selection,d) else GlyphPositionResult(p,status,0,0) end
