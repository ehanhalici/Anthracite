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
staload "data_font/sfnt.sats"
fun checked(b: !Buf,info: SfntInfo,run: GlyphRun(2),scale: GlyphScale): GlyphPositionRead = let
  val+ ~GlyphRun(phase,meta,s)=run
  val cache=glyph_position_cache_make(airlock_nat(meta.used))
  val status=glyph_position_nominal_bytes(b,info,scale,s,meta,cache)
  val ()=if glyph_position_ready(status) then glyph_position_cache_commit(cache,s,meta.used) else ()
  val ()=glyph_position_cache_dispose(cache)
  val run=GlyphRun(phase,meta,s)
in if glyph_position_ready(status) then PositionInitialized(PositionAccumulating(run,scale)) else PositionRejected(run,status) end
implement glyph_position_initialize(face,run,x,y) = let val+ SfntFace(b,info)=face
in glyph_position_initialize_bytes(b,info,run,x,y) end
implement glyph_position_initialize_bytes(b,info,run,x,y) = let val meta=glyph_run_meta(run)
  val scale: GlyphScale= @{units=info.units,xPpem=x,yPpem=y}
in if ine(info.glyphs,meta.glyphs) orelse ilt(x,1) orelse igt(x,65535) orelse ilt(y,1) orelse igt(y,65535)
  then PositionRejected(run,PositionDomain()) else checked(b,info,run,scale) end
