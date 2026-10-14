#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run.sats"
implement glyph_run_reserve(run,capacity) =
  if not(glyph_storage_capacity(capacity)) then GlyphRunEdited(run,GlyphCapacity(),~1) else let
    val+ ~GlyphRun(phase,meta,storage)=run
  in if ile(capacity,glyph_storage_count(storage)) then GlyphRunEdited(GlyphRun(phase,meta,storage),GlyphUnchanged(),~1) else let
    val target=glyph_storage_make(airlock_nat(capacity))
    val ()=glyph_storage_copy(storage,target,meta.used)
    val ()=glyph_storage_dispose(storage)
  in GlyphRunEdited(GlyphRun(phase,meta,target),GlyphUpdated(),~1) end end
