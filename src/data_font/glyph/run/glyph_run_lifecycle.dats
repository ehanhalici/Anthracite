#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run.sats"
implement glyph_run_make(font,glyphs,sourceLength,capacity) =
  if ilt(font,0) orelse ilt(glyphs,1) orelse igt(glyphs,WORD16_MAX_VALUE) then GlyphRunRejected(GlyphDomain())
  else if ilt(sourceLength,0) then GlyphRunRejected(GlyphSource())
  else if not(glyph_storage_capacity(capacity)) then GlyphRunRejected(GlyphCapacity()) else
    GlyphRunCreated(GlyphRun(RunNominal(),@{used=0,live=0,head= ~1,tail= ~1,font=font,glyphs=glyphs,
      sourceLength=sourceLength,nextLigature=1,properties=GlyphSourceRaw()},glyph_storage_make(airlock_nat(capacity))))
implement glyph_run_substitute(run) = let val+ ~GlyphRun(phase,meta,s)=run in GlyphRun(RunSubstitution(),meta,s) end
implement glyph_run_position(run) = let val+ ~GlyphRun(phase,meta,s)=run in GlyphRun(RunPositioning(),meta,s) end
implement glyph_run_freeze(run) = let val+ ~GlyphRun(phase,meta,s)=run in GlyphRun(RunFrozen(),meta,s) end
implement glyph_run_meta(run) = let val+ GlyphRun(phase,meta,s)=run in meta end
implement glyph_run_capacity(run) = let val+ GlyphRun(phase,meta,s)=run in glyph_storage_count(s) end
implement glyph_run_dispose(run) = let val+ ~GlyphRun(phase,meta,s)=run in glyph_storage_dispose(s) end
